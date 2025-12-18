import 'dart:async';

import 'package:fetch/src/core/payload.dart';
import 'package:fetch/src/core/response.dart';
import 'package:fetch/src/utils/exception.dart';

/// Thrown to skip the HTTP request and return a cached/mock response
class SkipRequest implements Exception {
  SkipRequest(this.response);
  final FetchResponse response;
}

/// Abstract Interceptor class
abstract class Interceptor {
  /// Called before request is sent.
  /// Return modified payload or throw [SkipRequest] to skip the request.
  FutureOr<FetchPayload> onRequest(FetchPayload payload) => payload;

  /// Called after response is received
  FutureOr<FetchResponse> onResponse(
    FetchResponse response,
    FetchPayload payload,
  ) =>
      response;

  /// Called when an error occurs
  FutureOr<void> onError(FetchException error) {}
}

/// Request/Response logging interceptor
class LogInterceptor extends Interceptor {
  LogInterceptor({this.logRequest = true, this.logResponse = true});

  final bool logRequest;
  final bool logResponse;

  @override
  FetchPayload onRequest(FetchPayload payload) {
    if (logRequest) {
      print('→ ${payload.method} ${payload.uri}');
      if (payload.headers?.isNotEmpty ?? false) {
        print('  Headers: ${payload.headers}');
      }
      if (payload.body != null) {
        print('  Body: ${payload.body}');
      }
    }
    return payload;
  }

  @override
  FetchResponse onResponse(FetchResponse response, FetchPayload payload) {
    if (logResponse) {
      print('← ${response.response.statusCode} ${payload.uri}');
    }
    return response;
  }

  @override
  void onError(FetchException error) {
    print('✗ Error: ${error.message}');
  }
}

/// Auth token interceptor
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.getToken});

  final FutureOr<String?> Function() getToken;

  @override
  Future<FetchPayload> onRequest(FetchPayload payload) async {
    final token = await getToken();
    if (token != null) {
      return payload.copyWith(
        headers: {
          ...?payload.headers,
          'Authorization': 'Bearer $token',
        },
      );
    }
    return payload;
  }
}

/// Debounce interceptor
///
/// Prevents rapid duplicate requests by debouncing them.
/// Only the last request within the debounce duration will execute.
/// Each new request resets the timer, so early requests are cancelled.
class DebounceInterceptor extends Interceptor {
  DebounceInterceptor({required this.duration})
      : _lastRequestTime = {},
        _timers = {},
        _completers = {};

  final Duration duration;
  final Map<String, DateTime> _lastRequestTime;
  final Map<String, Timer> _timers;
  final Map<String, Completer<void>> _completers;

  @override
  Future<FetchPayload> onRequest(FetchPayload payload) async {
    if (duration == Duration.zero) {
      return payload;
    }

    final key = payload.uri.toString();
    final now = DateTime.now();

    // Cancel previous timer and reject previous request
    final previousTimer = _timers[key];
    if (previousTimer != null && previousTimer.isActive) {
      previousTimer.cancel();
      // Complete the previous request's completer with error
      final previousCompleter = _completers[key];
      if (previousCompleter != null && !previousCompleter.isCompleted) {
        previousCompleter.completeError(
          FetchException(
            payload: payload,
            type: FetchExceptionType.debounced,
          ),
        );
      }
    }

    // Create new completer for this request
    final completer = Completer<void>();
    _completers[key] = completer;
    _lastRequestTime[key] = now;

    // Set timer to complete after debounce duration
    _timers[key] = Timer(duration, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
      _timers.remove(key);
      _completers.remove(key);
    });

    // Wait for either completion or cancellation
    await completer.future;
    return payload;
  }

  /// Clear all debounce state
  void clear() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _completers.clear();
    _lastRequestTime.clear();
  }

  /// Clear debounce state for specific endpoint
  void clearKey(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
    _completers.remove(key);
    _lastRequestTime.remove(key);
  }
}

/// Throttle interceptor
///
/// Prevents rapid duplicate requests by throttling them.
/// Only the first request within the throttle duration will execute.
/// Subsequent requests within the duration will be rejected.
class ThrottleInterceptor extends Interceptor {
  ThrottleInterceptor({required this.duration}) : _lastExecuted = {};

  final Duration duration;
  final Map<String, DateTime> _lastExecuted;

  @override
  FetchPayload onRequest(FetchPayload payload) {
    if (duration == Duration.zero) {
      return payload;
    }

    final key = payload.uri.toString();
    final now = DateTime.now();

    // Check if there's a recent request
    final lastExecution = _lastExecuted[key];
    if (lastExecution != null) {
      final elapsed = now.difference(lastExecution);
      if (elapsed < duration) {
        // Throw throttle exception
        throw FetchException(
          payload: payload,
          type: FetchExceptionType.throttled,
        );
      }
    }

    // Update last execution time
    _lastExecuted[key] = now;

    return payload;
  }

  /// Clear all throttle state
  void clear() {
    _lastExecuted.clear();
  }

  /// Clear throttle state for specific endpoint
  void clearKey(String key) {
    _lastExecuted.remove(key);
  }
}

/// Cache interceptor
///
/// Caches responses based on the configured strategy and duration.
class CacheInterceptor extends Interceptor {
  CacheInterceptor({
    required this.duration,
    this.strategy = CacheStrategy.fullUrl,
    this.canCache,
  }) : _cache = {};

  final Duration duration;
  final CacheStrategy strategy;
  final bool Function(FetchResponse response)? canCache;
  final Map<Uri, _CacheEntry> _cache;

  Uri _getCacheKey(Uri uri) {
    return switch (strategy) {
      CacheStrategy.urlWithoutQuery => uri.replace(query: ''),
      CacheStrategy.fullUrl => uri,
    };
  }

  @override
  FetchPayload onRequest(FetchPayload payload) {
    if (duration == Duration.zero) {
      return payload;
    }

    final key = _getCacheKey(payload.uri);
    final cached = _cache[key];

    // Return cached response if available and not expired
    if (cached != null && !cached.isExpired) {
      throw SkipRequest(cached.response);
    }

    return payload;
  }

  @override
  FetchResponse onResponse(FetchResponse response, FetchPayload payload) {
    if (duration == Duration.zero) {
      return response;
    }

    // Check if response can be cached
    if (canCache != null && !canCache!(response)) {
      return response;
    }

    // Cache the response
    final key = _getCacheKey(payload.uri);
    _cache[key] = _CacheEntry(response, duration);

    return response;
  }

  /// Clear all cached responses
  void clearCache() {
    _cache.clear();
  }

  /// Clear cached response for specific URI
  void clearCacheFor(Uri uri) {
    final key = _getCacheKey(uri);
    _cache.remove(key);
  }
}

/// Internal cache entry
class _CacheEntry {
  _CacheEntry(this.response, this.duration) : date = DateTime.now();

  final FetchResponse response;
  final Duration duration;
  final DateTime date;

  bool get isExpired => date.add(duration).isBefore(DateTime.now());
}

/// Cache strategy enum
enum CacheStrategy {
  urlWithoutQuery,
  fullUrl,
}

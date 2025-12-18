import 'dart:async';

import 'package:fetch/src/core/payload.dart';
import 'package:fetch/src/core/response.dart';
import 'package:fetch/src/utils/exception.dart';

/// Result from interceptor processing
sealed class InterceptorResult {}

/// Continue with the request
class ContinueRequest extends InterceptorResult {
  ContinueRequest(this.payload);
  final FetchPayload payload;
}

/// Skip the request and return this response immediately
class SkipRequest extends InterceptorResult {
  SkipRequest(this.response);
  final FetchResponse response;
}

/// Abstract Interceptor class
abstract class Interceptor {
  /// Called before request is sent
  /// Can return modified payload, or skip the request entirely
  FutureOr<InterceptorResult> onRequest(FetchPayload payload) =>
      ContinueRequest(payload);

  /// Called after response is received
  FutureOr<FetchResponse> onResponse(FetchResponse response) => response;

  /// Called when an error occurs
  FutureOr<void> onError(FetchException error) {}
}

/// Request/Response logging interceptor
class LogInterceptor extends Interceptor {
  LogInterceptor({this.logRequest = true, this.logResponse = true});

  final bool logRequest;
  final bool logResponse;

  @override
  InterceptorResult onRequest(FetchPayload payload) {
    if (logRequest) {
      print('→ ${payload.method} ${payload.uri}');
      if (payload.headers?.isNotEmpty ?? false) {
        print('  Headers: ${payload.headers}');
      }
      if (payload.body != null) {
        print('  Body: ${payload.body}');
      }
    }
    return ContinueRequest(payload);
  }

  @override
  FetchResponse onResponse(FetchResponse response) {
    if (logResponse) {
      print(
          '← ${response.response.statusCode} ${response.response.request?.url}');
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
  Future<InterceptorResult> onRequest(FetchPayload payload) async {
    final token = await getToken();
    if (token != null) {
      return ContinueRequest(
        payload.copyWith(
          headers: {
            ...?payload.headers,
            'Authorization': 'Bearer $token',
          },
        ),
      );
    }
    return ContinueRequest(payload);
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
  Future<InterceptorResult> onRequest(FetchPayload payload) async {
    if (duration == Duration.zero) {
      return ContinueRequest(payload);
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
    try {
      await completer.future;
      return ContinueRequest(payload);
    } catch (e) {
      rethrow;
    }
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
  InterceptorResult onRequest(FetchPayload payload) {
    if (duration == Duration.zero) {
      return ContinueRequest(payload);
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

    return ContinueRequest(payload);
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
  InterceptorResult onRequest(FetchPayload payload) {
    if (duration == Duration.zero) {
      return ContinueRequest(payload);
    }

    final key = _getCacheKey(payload.uri);
    final cached = _cache[key];

    // Return cached response if available and not expired
    if (cached != null && !cached.isExpired) {
      return SkipRequest(cached.response);
    }

    return ContinueRequest(payload);
  }

  @override
  FetchResponse onResponse(FetchResponse response) {
    if (duration == Duration.zero) {
      return response;
    }

    // Check if response can be cached
    if (canCache != null && !canCache!(response)) {
      return response;
    }

    // Cache the response
    final key = _getCacheKey(response.payload.uri);
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

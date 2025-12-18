import 'dart:async';

import 'package:fetch/src/core/payload.dart';
import 'package:fetch/src/core/response.dart';
import 'package:fetch/src/utils/exception.dart';

/// Thrown to skip the HTTP request and return a cached/mock response
class SkipRequest implements Exception {
  SkipRequest(this.response);
  final FetchResponse response;
}

/// Abstract FetchPipeline class for request/response processing
///
/// Pipelines are executed in order for requests and responses.
/// Each pipeline can modify the payload/response or skip the request entirely.
abstract class FetchPipeline {
  /// Called before request is sent.
  /// Return modified payload or throw [SkipRequest] to skip the request.
  FutureOr<FetchPayload> onRequest(FetchPayload payload) => payload;

  /// Called after response is received
  FutureOr<FetchResponse> onResponse(FetchResponse response) => response;

  /// Called when an error occurs
  FutureOr<void> onError(FetchException error) {}
}

/// Request/Response logging pipeline
class LogPipeline extends FetchPipeline {
  LogPipeline({this.logRequest = true, this.logResponse = true});

  final bool logRequest;
  final bool logResponse;

  @override
  FetchPayload onRequest(FetchPayload payload) {
    if (logRequest) {
      // ignore: avoid_print
      print('→ ${payload.method} ${payload.uri}');
      if (payload.headers?.isNotEmpty ?? false) {
        // ignore: avoid_print
        print('  Headers: ${payload.headers}');
      }
      if (payload.body != null) {
        // ignore: avoid_print
        print('  Body: ${payload.body}');
      }
    }
    return payload;
  }

  @override
  FetchResponse onResponse(FetchResponse response) {
    if (logResponse) {
      // ignore: avoid_print
      print('← ${response.response.statusCode} ${response.payload.uri}');
    }
    return response;
  }
}

/// Auth token pipeline
class AuthPipeline extends FetchPipeline {
  AuthPipeline({required this.getToken});

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

/// Debounce pipeline
///
/// Prevents rapid duplicate requests by debouncing them.
/// Only the last request within the debounce duration will execute.
/// Each new request resets the timer, so early requests are cancelled.
class DebouncePipeline extends FetchPipeline {
  DebouncePipeline({required this.duration});

  final Duration duration;
  final Map<String, _DebounceState> _states = {};

  @override
  Future<FetchPayload> onRequest(FetchPayload payload) async {
    if (duration == Duration.zero) {
      return payload;
    }

    final key = payload.uri.toString();

    // Cancel previous request if exists
    final previous = _states[key];
    if (previous != null) {
      previous.timer.cancel();
      if (!previous.completer.isCompleted) {
        previous.completer.completeError(
          FetchException(
            payload: payload,
            type: FetchExceptionType.debounced,
          ),
        );
      }
    }

    // Create new state
    final completer = Completer<void>();
    final timer = Timer(duration, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
      _states.remove(key);
    });
    _states[key] = _DebounceState(timer, completer);

    await completer.future;
    return payload;
  }

  /// Clear all debounce state
  void clear() {
    for (final state in _states.values) {
      state.timer.cancel();
    }
    _states.clear();
  }

  /// Clear debounce state for specific endpoint
  void clearKey(String key) {
    _states[key]?.timer.cancel();
    _states.remove(key);
  }
}

/// Throttle pipeline
///
/// Prevents rapid duplicate requests by throttling them.
/// Only the first request within the throttle duration will execute.
/// Subsequent requests within the duration will be rejected.
class ThrottlePipeline extends FetchPipeline {
  ThrottlePipeline({required this.duration}) : _lastExecuted = {};

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

/// Internal state for debounce
class _DebounceState {
  _DebounceState(this.timer, this.completer);
  final Timer timer;
  final Completer<void> completer;
}

/// Type alias for response validator function
///
/// Returns error message if validation fails, null if valid.
/// Receives the response and can inspect status code, body, etc.
typedef ResponseValidator = FutureOr<String?> Function(FetchResponse response);

/// Response validation pipeline for business logic errors
///
/// Use this pipeline to validate responses for business logic errors.
/// Even if HTTP status is 2xx, your API might return success: false
/// or similar patterns in the body.
///
/// Example:
/// ```dart
/// final fetch = Fetch<FetchResponse>(
///   executor: Executor(
///     pipelines: [
///       ResponseValidatorPipeline(
///         validator: (response) {
///           final json = jsonDecode(response.response.body);
///           if (json['success'] == false) {
///             return json['message'] ?? 'Request failed';
///           }
///           return null; // Valid response
///         },
///       ),
///     ],
///   ),
/// );
/// ```
class ResponseValidatorPipeline extends FetchPipeline {
  ResponseValidatorPipeline({required this.validator});

  /// Validator function that returns error message if invalid, null if valid
  final ResponseValidator validator;

  @override
  Future<FetchResponse> onResponse(FetchResponse response) async {
    final errorMessage = await validator(response);

    if (errorMessage != null) {
      throw FetchException(
        type: FetchExceptionType.custom,
        payload: response.payload,
        message: errorMessage,
        statusCode: response.response.statusCode,
        responseBody: response.response.body,
      );
    }

    return response;
  }
}

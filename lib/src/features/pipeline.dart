import 'dart:async';

import 'package:fetch/src/core/request.dart';
import 'package:fetch/src/core/result.dart';

/// Thrown to skip the HTTP request and return a cached/mock response
class SkipRequest implements Exception {
  SkipRequest(this.result);
  final FetchResult result;
}

/// Abstract FetchPipeline class for request/response processing
///
/// Pipelines are executed in order for requests and responses.
/// Each pipeline can modify the payload/response or skip the request entirely.
abstract class FetchPipeline<T extends FetchResult> {
  /// Called before request is sent.
  /// Return modified payload or throw [SkipRequest] to skip the request.
  FutureOr<FetchRequest> onRequest(FetchRequest request) => request;

  /// Called after response is received
  FutureOr<T> onResult(T result) => result;
}

/// Request/Response logging pipeline
class LoggerPipeline<T extends FetchResult> extends FetchPipeline<T> {
  final List<dynamic> logs = [];

  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;

    if (!value) {
      logs.clear();
    }
  }

  void onLog(dynamic value) {
    logs.add(value);
  }

  void onLogRequest(FetchRequest request) {
    if (!enabled) {
      return;
    }

    onLog(request);
  }

  void onLogResult(T result) {
    if (!enabled) {
      return;
    }

    onLog(result);
  }

  @override
  FutureOr<FetchRequest> onRequest(FetchRequest request) {
    onLogRequest(request);
    return request;
  }

  @override
  FutureOr<T> onResult(T result) {
    onLogResult(result);
    return result;
  }
}

/// Auth token pipeline
class AuthPipeline<T extends FetchResult> extends FetchPipeline<T> {
  AuthPipeline({required this.getToken});

  final FutureOr<String?> Function() getToken;

  @override
  FutureOr<FetchRequest> onRequest(FetchRequest request) async {
    final token = await getToken();
    if (token != null) {
      return request.copyWith(
        headers: {...?request.headers, 'Authorization': 'Bearer $token'},
      );
    }
    return request;
  }
}

/// Debounce pipeline
///
/// Prevents rapid duplicate requests by debouncing them.
/// Only the last request within the debounce duration will execute.
/// Each new request resets the timer, so early requests are cancelled.
class DebouncePipeline<T extends FetchResult> extends FetchPipeline<T> {
  DebouncePipeline({required this.duration});

  final Duration duration;
  final Map<String, _DebounceState> _states = {};

  @override
  FutureOr<FetchRequest> onRequest(FetchRequest request) async {
    if (duration == Duration.zero) {
      return request;
    }

    final key = request.uri.toString();

    // Cancel previous request if exists
    final previous = _states[key];
    if (previous != null) {
      previous.timer.cancel();
      if (!previous.completer.isCompleted) {
        previous.completer.completeError(
          FetchException.debounced(request: request),
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
    return request;
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
class ThrottlePipeline<T extends FetchResult> extends FetchPipeline<T> {
  ThrottlePipeline({required this.duration}) : _lastExecuted = {};

  final Duration duration;
  final Map<String, DateTime> _lastExecuted;

  @override
  FutureOr<FetchRequest> onRequest(FetchRequest request) {
    if (duration == Duration.zero) {
      return request;
    }

    final key = request.uri.toString();
    final now = DateTime.now();

    // Check if there's a recent request
    final lastExecution = _lastExecuted[key];
    if (lastExecution != null) {
      final elapsed = now.difference(lastExecution);
      if (elapsed < duration) {
        // Throw throttle exception
        throw FetchException.throttled(request: request);
      }
    }

    // Update last execution time
    _lastExecuted[key] = now;

    return request;
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
typedef ResponseValidator = FutureOr<String?> Function(FetchResult result);

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
class ResponseValidatorPipeline<T extends FetchResult>
    extends FetchPipeline<T> {
  ResponseValidatorPipeline({required this.validator});

  /// Validator function that returns error message if invalid, null if valid
  final ResponseValidator validator;

  @override
  FutureOr<T> onResult(T result) async {
    final errorMessage = await validator(result);

    if (errorMessage != null) {
      throw FetchException.custom(
        request: result.request,
        message: errorMessage,
      );
    }

    return result;
  }
}

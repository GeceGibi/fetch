import 'dart:async';

import 'package:via/src/core/request.dart';
import 'package:via/src/core/result.dart';

/// Thrown to skip the HTTP request and return a cached/mock response
class SkipRequest implements Exception {
  SkipRequest(this.result);
  final ViaBaseResult result;
}

/// Abstract ViaPipeline class for request/response processing
///
/// Pipelines are executed in order for requests and responses.
/// Each pipeline can modify the payload/response or skip the request entirely.
abstract class ViaPipeline {
  const ViaPipeline();

  /// Called before request is sent.
  /// Return modified request or throw [SkipRequest] to skip execution.
  FutureOr<ViaRequest> onRequest(ViaRequest request) => request;

  /// Called when a streaming response is received.
  /// Use this to intercept, log, or transform the stream data chunks.
  Stream<List<int>> onResultStream(ViaResultStream result) => result.stream;

  /// Called after buffered response is received.
  FutureOr<ViaResult> onResult(ViaResult result) => result;

  /// Called when an error occurs during processing.
  void onError(ViaException error) {}
}

/// Simple pipeline for logging request, result, and error events.
///
/// By default, it records events in the [logs] list.
/// Override [onLog] to perform real-time logging (e.g., print to console).
class ViaLoggerPipeline extends ViaPipeline {
  ViaLoggerPipeline({
    bool enabled = true,
    this.maxEntries = 100,
    this.includeRequest = true,
    this.includeResult = true,
    this.includeError = true,
    this.includeStream = true,
  }) : _enabled = enabled;

  bool _enabled;

  /// Whether logging is currently enabled.
  bool get enabled => _enabled;

  set enabled(bool value) {
    _enabled = value;
    if (!value) logs.clear();
  }

  /// Maximum number of events to keep in the [logs] list.
  final int maxEntries;

  /// Whether to include request events in the [logs] list.
  final bool includeRequest;

  /// Whether to include result events in the [logs] list.
  final bool includeResult;

  /// Whether to include error events in the [logs] list.
  final bool includeError;

  /// Whether to include stream events in the [logs] list.
  final bool includeStream;

  /// History of captured events.
  ///
  /// Each entry can be one of the following types:
  /// - [ViaRequest]: Recorded when a request is about to be sent.
  /// - [ViaBaseResult]: Recorded when a successful response is received.
  /// - [ViaException]: Recorded when a request fails or is rejected by a pipeline.
  final List<Object> logs = [];

  void _addLog(Object event) {
    if (!enabled) return;

    if (logs.length >= maxEntries && maxEntries > 0) {
      logs.removeAt(0);
    }

    // Convert to isolate-safe version if possible
    var safeEvent = event;

    if (event is ViaRequest) {
      safeEvent = event.toSafeVersion();
    } else if (event is ViaBaseResult) {
      safeEvent = event.toSafeVersion();
    }

    logs.add(safeEvent);
    onLog(event);
  }

  @override
  ViaRequest onRequest(ViaRequest request) {
    if (includeRequest) _addLog(request);
    return request;
  }

  @override
  ViaResult onResult(ViaResult result) {
    if (includeResult) _addLog(result);
    return result;
  }

  @override
  Stream<List<int>> onResultStream(ViaResultStream result) {
    if (includeStream) _addLog(result);
    if (!enabled) return result.stream;

    return result.stream.transform(
      StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) {
          final viaError = error is ViaException
              ? error
              : ViaException.network(
                  request: result.request,
                  message: error.toString(),
                  stackTrace: stackTrace,
                );
          onError(viaError);
          sink.addError(viaError, stackTrace);
        },
      ),
    );
  }

  @override
  void onError(ViaException error) {
    if (includeError) _addLog(error);
  }

  /// Hook for real-time logging. Override this to handle events as they occur.
  void onLog(Object event) {}
}

/// Auth token pipeline
class ViaAuthPipeline extends ViaPipeline {
  ViaAuthPipeline({required this.getToken});

  final FutureOr<String?> Function() getToken;

  @override
  FutureOr<ViaRequest> onRequest(ViaRequest request) async {
    final token = await getToken();

    if (token != null) {
      return request.copyWith(
        headers: {
          ...?request.headers,
          'Authorization': 'Bearer $token',
        },
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
class ViaDebouncePipeline extends ViaPipeline {
  ViaDebouncePipeline({required this.duration});

  final Duration duration;
  final Map<String, _DebounceState> _states = {};

  @override
  FutureOr<ViaRequest> onRequest(ViaRequest request) async {
    if (duration == Duration.zero) {
      return request;
    }

    final key = '${request.method}:${request.uri}';

    // Cancel previous request if exists
    final previous = _states[key];
    if (previous != null) {
      previous.timer.cancel();
      if (!previous.completer.isCompleted) {
        previous.completer.completeError(
          ViaException.debounced(request: request),
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

    try {
      await completer.future;
      return request;
    } catch (_) {
      _states.remove(key);
      rethrow;
    }
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
class ViaThrottlePipeline extends ViaPipeline {
  ViaThrottlePipeline({required this.duration}) : _lastExecuted = {};

  final Duration duration;
  final Map<String, DateTime> _lastExecuted;

  @override
  FutureOr<ViaRequest> onRequest(ViaRequest request) {
    if (duration == Duration.zero) {
      return request;
    }

    final key = '${request.method}:${request.uri}';
    final now = DateTime.now();

    // Check if there's a recent request
    final lastExecution = _lastExecuted[key];
    if (lastExecution != null) {
      final elapsed = now.difference(lastExecution);
      if (elapsed < duration) {
        // Throw throttle exception
        throw ViaException.throttled(request: request);
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
typedef ResponseValidator = FutureOr<String?> Function(ViaBaseResult result);

/// Response validation pipeline for business logic errors
///
/// Use this pipeline to validate responses for business logic errors.
/// Even if HTTP status is 2xx, your API might return success: false
/// or similar patterns in the body.
class ViaResponseValidatorPipeline extends ViaPipeline {
  ViaResponseValidatorPipeline({required this.validator});

  /// Validator function that returns error message if invalid, null if valid
  final ResponseValidator validator;

  @override
  Stream<List<int>> onResultStream(ViaResultStream result) async* {
    final errorMessage = await validator(result);

    if (errorMessage != null) {
      throw result.toException(message: errorMessage);
    }

    yield* result.stream;
  }

  @override
  FutureOr<ViaResult> onResult(ViaResult result) async {
    final errorMessage = await validator(result);

    if (errorMessage != null) {
      throw result.toException(message: errorMessage);
    }

    return result;
  }
}

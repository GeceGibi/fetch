import 'dart:async';
import 'dart:convert';

import 'package:via/src/core/request.dart';
import 'package:via/src/core/result.dart';

/// Thrown to skip the HTTP request and return a cached/mock response
class SkipRequest implements Exception {
  SkipRequest(this.result);
  final ViaResult result;
}

/// Abstract ViaPipeline class for request/response processing
///
/// Pipelines are executed in order for requests and responses.
/// Each pipeline can modify the payload/response or skip the request entirely.
abstract class ViaPipeline<T extends ViaResult> {
  /// Called before request is sent.
  /// Return modified request or throw [SkipRequest] to skip execution.
  FutureOr<ViaRequest> onRequest(ViaRequest request) => request;

  /// Called after response is received.
  FutureOr<T> onResult(T result) => result;

  /// Called when an error occurs during processing.
  void onError(ViaException error) {}
}

/// Request/Response logging pipeline
class ViaLoggerPipeline<T extends ViaResult> extends ViaPipeline<T> {
  ViaLoggerPipeline({
    this.includeCurl = true,
    this.includeResponse = true,
    this.onLog,
  });

  /// Whether to include cURL command in logs
  final bool includeCurl;

  /// Whether to include response body in logs
  final bool includeResponse;

  /// Custom log handler (defaults to print)
  final void Function(String message)? onLog;

  void _log(String message) {
    if (onLog != null) {
      onLog!(message);
    } else {
      // ignore: avoid_print
      print(message);
    }
  }

  @override
  FutureOr<ViaRequest> onRequest(ViaRequest request) {
    _log('--- HTTP Request ---');
    _log('${request.method} ${request.uri}');

    if (request.headers?.isNotEmpty ?? false) {
      _log('Headers: ${request.headers}');
    }

    if (includeCurl) {
      _log('cURL: ${_toCurl(request)}');
    }

    return request;
  }

  @override
  FutureOr<T> onResult(T result) {
    _log('--- HTTP Response ---');
    _log('Status: ${result.response.statusCode} (${result.isSuccess ? 'Success' : 'Failure'})');
    _log('Elapsed: ${result.elapsed?.inMilliseconds}ms');

    if (includeResponse) {
      _log('Body: ${result.response.body}');
    }

    return result;
  }

  @override
  void onError(ViaException error) {
    _log('--- HTTP Error ---');
    _log('Type: ${error.type.name}');
    _log('Message: ${error.message}');
    if (error.response != null) {
      _log('Status: ${error.response!.statusCode}');
      _log('Body: ${error.response!.body}');
    }
  }

  String _toCurl(ViaRequest request) {
    final components = ['curl -X ${request.method}'];

    request.headers?.forEach((key, value) {
      components.add('-H "$key: $value"');
    });

    if (request.body != null) {
      if (request.body is String) {
        components.add('-d \'${request.body}\'');
      } else if (request.body is Map) {
        components.add('-d \'${jsonEncode(request.body)}\'');
      }
    }

    components.add('"${request.uri}"');

    return components.join(' ');
  }
}

/// Auth token pipeline
class ViaAuthPipeline<T extends ViaResult> extends ViaPipeline<T> {
  ViaAuthPipeline({required this.getToken});

  final FutureOr<String?> Function() getToken;

  @override
  FutureOr<ViaRequest> onRequest(ViaRequest request) async {
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
class ViaDebouncePipeline<T extends ViaResult> extends ViaPipeline<T> {
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
class ViaThrottlePipeline<T extends ViaResult> extends ViaPipeline<T> {
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
typedef ResponseValidator = FutureOr<String?> Function(ViaResult result);

/// Response validation pipeline for business logic errors
///
/// Use this pipeline to validate responses for business logic errors.
/// Even if HTTP status is 2xx, your API might return success: false
/// or similar patterns in the body.
///
/// Example:
/// ```dart
/// final via = Via(
///   executor: ViaExecutor(
///     pipelines: [
///       ViaResponseValidatorPipeline(
///         validator: (result) {
///           if (result.response.body.contains('error')) {
///             return 'Business Error';
///           }
///           return null;
///         },
///       ),
///     ],
///   ),
/// );
/// ```
class ViaResponseValidatorPipeline<T extends ViaResult> extends ViaPipeline<T> {
  ViaResponseValidatorPipeline({required this.validator});

  /// Validator function that returns error message if invalid, null if valid
  final ResponseValidator validator;

  @override
  FutureOr<T> onResult(T result) async {
    final errorMessage = await validator(result);

    if (errorMessage != null) {
      throw ViaException.custom(
        request: result.request,
        message: errorMessage,
      );
    }

    return result;
  }
}

import 'dart:async';
import 'dart:isolate';

import 'package:fetch/src/core/payload.dart';
import 'package:fetch/src/core/response.dart';
import 'package:http/http.dart' as http;

/// Type alias for the method function that executes HTTP requests
typedef ExecutorMethod = Future<FetchResponse> Function(FetchPayload payload);

/// Type alias for the transform function that converts responses
typedef TransformFunction<R> = FutureOr<R> Function(FetchResponse response);

/// Type alias for isolate-safe transform functions (top-level or static only)
typedef IsolateTransformFunction = dynamic Function(http.Response response);

/// Abstract class for request execution strategies.
///
/// This allows platform-specific implementations like isolate-based
/// execution for mobile/desktop or direct execution for web.
abstract class RequestExecutor {
  /// Creates a default executor that runs in the main isolate
  factory RequestExecutor.direct() = DefaultExecutor;

  /// Creates an isolate-based executor for CPU-intensive operations
  ///
  /// [isolateTransform] - Top-level or static function for transform in isolate
  factory RequestExecutor.isolate({
    IsolateTransformFunction? isolateTransform,
  }) = IsolateExecutor;

  /// Executes the request with the given payload and transforms the response.
  ///
  /// [payload] - The request payload
  /// [method] - The function that performs the actual HTTP request
  /// [transform] - Optional function to transform the response
  ///
  /// Returns the transformed result or FetchResponse if no transform provided
  Future<R> execute<R>(
    FetchPayload payload,
    ExecutorMethod method,
    TransformFunction<R>? transform,
  );
}

/// Default executor that runs requests and transforms in the main isolate.
///
/// This is suitable for web platforms and simple use cases where
/// isolate overhead is not needed.
class DefaultExecutor implements RequestExecutor {
  @override
  Future<R> execute<R>(
    FetchPayload payload,
    ExecutorMethod method,
    TransformFunction<R>? transform,
  ) async {
    final response = await method(payload);

    if (transform == null) {
      return response as R;
    }

    return await transform(response);
  }
}

/// Isolate-based executor for CPU-intensive operations.
///
/// Runs HTTP requests and transforms in a separate isolate.
/// Provide an `isolateTransform` function (must be top-level or static).
///
/// Note: Not supported on web platforms.
class IsolateExecutor implements RequestExecutor {
  /// Creates an isolate executor with optional isolate-safe transform
  const IsolateExecutor({this.isolateTransform});

  /// Isolate-safe transform function (must be top-level or static)
  final IsolateTransformFunction? isolateTransform;

  @override
  Future<R> execute<R>(
    FetchPayload payload,
    ExecutorMethod method,
    TransformFunction<R>? transform,
  ) async {
    final receivePort = ReceivePort();

    try {
      await Isolate.spawn(
        _isolateEntry<R>,
        _IsolateMessage<R>(
          sendPort: receivePort.sendPort,
          payload: payload,
          method: method,
          isolateTransform: isolateTransform,
        ),
      );

      final result = await receivePort.first;

      if (result is _IsolateError) {
        throw result.error;
      }

      // Result is already transformed in isolate
      return result as R;
    } finally {
      receivePort.close();
    }
  }

  /// Entry point for the isolate
  static Future<void> _isolateEntry<R>(_IsolateMessage<R> message) async {
    try {
      final fetchResponse = await message.method(message.payload);

      final R result;
      if (message.isolateTransform != null) {
        result = await message.isolateTransform!(fetchResponse.response) as R;
      } else {
        result = fetchResponse as R;
      }

      message.sendPort.send(result);
    } catch (e, stackTrace) {
      message.sendPort.send(_IsolateError(e, stackTrace));
    }
  }
}

/// Message passed to the isolate containing execution context
class _IsolateMessage<R> {
  const _IsolateMessage({
    required this.sendPort,
    required this.payload,
    required this.method,
    this.isolateTransform,
  });

  final SendPort sendPort;
  final FetchPayload payload;
  final ExecutorMethod method;
  final IsolateTransformFunction? isolateTransform;
}

/// Error wrapper for isolate errors
class _IsolateError {
  const _IsolateError(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

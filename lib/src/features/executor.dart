import 'dart:async';
import 'dart:isolate';

import 'package:fetch/src/core/payload.dart';
import 'package:fetch/src/core/response.dart';

/// Type alias for the method function that executes HTTP requests
typedef ExecutorMethod = Future<FetchResponse> Function(FetchPayload payload);

/// Type alias for the transform function that converts responses
typedef TransformFunction<R> = FutureOr<R> Function(FetchResponse response);

/// Abstract class for request execution strategies.
///
/// This allows platform-specific implementations like isolate-based
/// execution for mobile/desktop or direct execution for web.
abstract class RequestExecutor {
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

  /// Creates a default executor that runs in the main isolate
  factory RequestExecutor.direct() = DefaultExecutor;

  /// Creates an isolate-based executor for CPU-intensive operations
  factory RequestExecutor.isolate() = IsolateExecutor;
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
/// This executor runs HTTP requests and response transformations in a
/// separate isolate to avoid blocking the main UI thread. Useful for:
/// - Large JSON parsing operations
/// - Heavy data transformations
/// - Multiple concurrent requests
///
/// Note: Not supported on web platforms.
class IsolateExecutor implements RequestExecutor {
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
          transform: transform,
        ),
      );

      final result = await receivePort.first;

      if (result is _IsolateError) {
        throw result.error;
      }

      return result as R;
    } finally {
      receivePort.close();
    }
  }

  /// Entry point for the isolate
  static Future<void> _isolateEntry<R>(_IsolateMessage<R> message) async {
    try {
      final response = await message.method(message.payload);

      final R result;
      if (message.transform == null) {
        result = response as R;
      } else {
        result = await message.transform!(response);
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
    this.transform,
  });

  final SendPort sendPort;
  final FetchPayload payload;
  final ExecutorMethod method;
  final TransformFunction<R>? transform;
}

/// Error wrapper for isolate errors
class _IsolateError {
  const _IsolateError(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

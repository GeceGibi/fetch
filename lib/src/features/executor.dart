import 'dart:async';
import 'dart:isolate';

import 'package:fetch/src/core/payload.dart';
import 'package:fetch/src/core/response.dart';

/// Type alias for the method function that executes HTTP requests
typedef ExecutorMethod = Future<FetchResponse> Function(FetchPayload payload);

/// Abstract class for request execution strategies.
abstract class RequestExecutor {
  /// Creates a default executor that runs in the main isolate
  const factory RequestExecutor.direct() = DefaultExecutor;

  /// Creates an isolate-based executor using Isolate.run
  const factory RequestExecutor.isolate() = IsolateExecutor;

  /// Executes the request with the given payload.
  Future<FetchResponse> execute(
    FetchPayload payload,
    ExecutorMethod method,
  );
}

/// Default executor that runs requests in the main isolate.
class DefaultExecutor implements RequestExecutor {
  const DefaultExecutor();

  @override
  Future<FetchResponse> execute(
    FetchPayload payload,
    ExecutorMethod method,
  ) async {
    return method(payload);
  }
}

/// Isolate-based executor using Isolate.run.
///
/// Runs HTTP requests in a separate isolate using Isolate.run.
/// Note: Not supported on web platforms.
class IsolateExecutor implements RequestExecutor {
  const IsolateExecutor();

  @override
  Future<FetchResponse> execute(
    FetchPayload payload,
    ExecutorMethod method,
  ) async {
    return Isolate.run(() => method(payload));
  }
}

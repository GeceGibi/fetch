import 'dart:async';
import 'dart:isolate';

import 'package:fetch/src/core/payload.dart';
import 'package:fetch/src/core/response.dart';
import 'package:fetch/src/utils/exception.dart';

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

/// Retry executor that wraps another executor with retry logic.
///
/// This executor automatically retries failed requests based on the
/// configured retry policy.
class RetryExecutor implements RequestExecutor {
  const RetryExecutor({
    required this.executor,
    this.maxAttempts = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.retryIf,
  });

  /// The underlying executor to use for requests
  final RequestExecutor executor;

  /// Maximum number of attempts (includes initial attempt)
  final int maxAttempts;

  /// Delay between retries
  final Duration retryDelay;

  /// Function to determine whether to retry
  /// If null, retries on server errors, connection errors, and timeouts
  final bool Function(FetchException error)? retryIf;

  bool _shouldRetry(FetchException error) {
    if (retryIf != null) {
      return retryIf!(error);
    }
    // Default: retry on server errors, connection errors, and timeouts
    return error.type == FetchExceptionType.httpError ||
        error.type == FetchExceptionType.connectionError ||
        error.type == FetchExceptionType.timeout;
  }

  @override
  Future<FetchResponse> execute(
    FetchPayload payload,
    ExecutorMethod method,
  ) async {
    var attempt = 0;

    while (true) {
      attempt++;

      try {
        return await executor.execute(payload, method);
      } on FetchException catch (e) {
        final shouldRetry = _shouldRetry(e);

        if (!shouldRetry || attempt >= maxAttempts) {
          rethrow;
        }

        // Wait before retry
        await Future<void>.delayed(retryDelay);
      }
    }
  }
}

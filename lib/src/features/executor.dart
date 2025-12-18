import 'dart:async';

import 'package:fetch/src/core/payload.dart';
import 'package:fetch/src/core/response.dart';
import 'package:fetch/src/features/pipeline.dart';
import 'package:fetch/src/utils/exception.dart';

/// Type alias for the method function that executes HTTP requests
typedef ExecutorMethod = Future<FetchResponse> Function(FetchPayload payload);

/// Type alias for custom runner (e.g., isolate execution)
///
/// Example:
/// ```dart
/// // Run in isolate
/// final runner = (method, payload) => Isolate.run(() => method(payload));
/// ```
typedef Runner = Future<FetchResponse> Function(
  ExecutorMethod method,
  FetchPayload payload,
);

/// Request executor that orchestrates pipelines, execution, and retry logic.
///
/// The executor handles the complete request lifecycle:
/// 1. Pre-request pipelines (can modify payload or skip request)
/// 2. Request execution (optionally via custom runner)
/// 3. Post-response pipelines
/// 4. Error handling and retry logic
///
/// Example:
/// ```dart
/// final executor = Executor(
///   pipelines: [
///     LogPipeline(),
///     AuthPipeline(getToken: () => token),
///   ],
///   maxAttempts: 3,
///   retryIf: (e) => e.statusCode != null && e.statusCode! >= 500,
/// );
/// ```
class Executor {
  /// Creates a new Executor.
  ///
  /// [pipelines] - List of pipelines to run on each request
  /// [runner] - Custom runner for execution (e.g., isolate). If null, runs directly.
  /// [maxAttempts] - Maximum retry attempts including initial (default: 1 = no retry)
  /// [retryDelay] - Delay between retries (default: 1 second)
  /// [retryIf] - Function to determine if request should be retried
  const Executor({
    this.pipelines = const [],
    this.runner,
    this.maxAttempts = 1,
    this.retryDelay = const Duration(seconds: 1),
    this.retryIf,
  });

  /// Pipelines to run on each request
  final List<FetchPipeline> pipelines;

  /// Custom runner for execution (e.g., for isolate-based execution)
  /// If null, the method is called directly
  final Runner? runner;

  /// Maximum retry attempts (includes initial attempt)
  /// Set to 1 for no retry, 2 for one retry, etc.
  final int maxAttempts;

  /// Delay between retry attempts
  final Duration retryDelay;

  /// Function to determine if request should be retried on error.
  /// Can be async (e.g., to refresh token before retry).
  /// Return true to retry, false to throw error.
  final FutureOr<bool> Function(FetchException error)? retryIf;

  /// Executes the request through pipelines.
  ///
  /// [payload] - Initial request payload
  /// [method] - The method to run the actual HTTP request
  /// [pipelines] - Additional pipelines for this specific request
  ///
  /// Returns the processed response after all pipelines have run.
  Future<FetchResponse> execute(
    FetchPayload payload, {
    required ExecutorMethod method,
    List<FetchPipeline> pipelines = const [],
  }) async {
    final pipes = [...this.pipelines, ...pipelines];

    var attempt = 0;

    while (true) {
      attempt++;

      try {
        return await _executeOnce(payload, method, pipes);
      } on FetchException catch (error) {
        // Check if should retry
        if (attempt < maxAttempts && retryIf != null) {
          final shouldRetry = await retryIf!(error);
          if (shouldRetry) {
            await Future<void>.delayed(retryDelay);
            // Loop continues → pipelines will re-run (important for token refresh)
            continue;
          }
        }

        // Run error pipelines before rethrowing
        for (final pipeline in pipes) {
          await pipeline.onError(error);
        }

        rethrow;
      }
    }
  }

  /// Executes a single attempt through pipelines and runner.
  Future<FetchResponse> _executeOnce(
    FetchPayload payload,
    ExecutorMethod method,
    List<FetchPipeline> pipelines,
  ) async {
    var currentPayload = payload;

    // 1. Pre-request pipelines - can modify payload or throw SkipRequest
    FetchResponse? skipResponse;
    try {
      for (final pipeline in pipelines) {
        currentPayload = await pipeline.onRequest(currentPayload);
      }
    } on SkipRequest catch (skip) {
      skipResponse = skip.response;
    }

    // 2. Execute request (or use skip response from cache/etc)
    final FetchResponse response;
    if (skipResponse != null) {
      response = skipResponse;
    } else if (runner != null) {
      response = await runner!(method, currentPayload);
    } else {
      response = await method(currentPayload);
    }

    // 3. Post-response pipelines (same order)
    var processedResponse = response;
    for (final pipeline in pipelines) {
      processedResponse = await pipeline.onResponse(processedResponse);
    }

    return processedResponse;
  }
}

import 'dart:async';

import 'package:fetch/src/core/request.dart';
import 'package:fetch/src/core/result.dart';
import 'package:fetch/src/features/pipeline.dart';
import 'package:fetch/src/features/retry.dart';

/// Type alias for the method function that executes HTTP requests
typedef ExecutorMethod<R extends FetchResult> =
    Future<R> Function(FetchRequest request);

/// Type alias for custom runner (e.g., isolate execution)
///
/// Example:
/// ```dart
/// // Run in isolate
/// final runner = (method, payload) => Isolate.run(() => method(payload));
/// ```
typedef Runner<R extends FetchResult> =
    Future<R> Function(ExecutorMethod<R> method, FetchRequest request);

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
class Executor<R extends FetchResult> {
  /// Creates a new Executor.
  ///
  /// [pipelines] - List of pipelines to run on each request
  /// [runner] - Custom runner for execution (e.g., isolate). If null, runs directly.
  const Executor({
    this.retry = const FetchRetry(),
    this.pipelines = const [],
    this.runner,
  });

  final FetchRetry retry;

  /// Pipelines to run on each request
  final List<FetchPipeline<R>> pipelines;

  /// Custom runner for execution (e.g., for isolate-based execution)
  /// If null, the method is called directly
  final Runner<R>? runner;

  /// Executes the request through pipelines.
  ///
  /// [request] - Initial request payload
  /// [method] - The method to run the actual HTTP request
  /// [pipelines] - Additional pipelines for this specific request
  ///
  /// Returns the processed response after all pipelines have run.
  Future<R> execute(
    FetchRequest request, {
    required ExecutorMethod<R> method,
    List<FetchPipeline<R>> pipelines = const [],
  }) async {
    final pipes = [...this.pipelines, ...pipelines];

    try {
      return retry.retry<R>(() => _executeOnce(request, method, pipes));
    } on FetchException catch (error) {
      for (final pipeline in pipes) {
        await pipeline.onResult(error as R);
      }

      rethrow;
    } catch (error, stackTrace) {
      final fetchException = FetchException.custom(
        request: request,
        stackTrace: stackTrace,
        message: error.toString(),
      );

      for (final pipeline in pipes) {
        await pipeline.onResult(fetchException as R);
      }

      throw fetchException;
    }
  }

  /// Executes a single attempt through pipelines and runner.
  Future<R> _executeOnce(
    FetchRequest request,
    ExecutorMethod<R> method,
    List<FetchPipeline<R>> pipelines,
  ) async {
    var currentRequest = request;
    // 1. Pre-request pipelines - can modify payload or throw SkipRequest
    R? skipResponse;
    try {
      for (final pipeline in pipelines) {
        currentRequest = await pipeline.onRequest(currentRequest);
      }
    } on SkipRequest catch (skip) {
      skipResponse = skip.result as R;
    }

    // 2. Execute request (or use skip response from cache/etc)
    final R response;
    final stopWatch = Stopwatch()..start();

    /// skip request execution and use cached response
    if (skipResponse != null) {
      response = skipResponse;
    }
    /// real request execution
    else if (runner != null) {
      response = await runner!(method, currentRequest);
    } else {
      response = await method(currentRequest);
    }

    response.elapsed = stopWatch.elapsed;

    // 3. Post-response pipelines (same order)
    var processedResponse = response;
    for (final pipeline in pipelines) {
      processedResponse = await pipeline.onResult(processedResponse);
    }

    return processedResponse;
  }
}

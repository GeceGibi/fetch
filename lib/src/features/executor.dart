import 'dart:async';

import 'package:via/src/core/request.dart';
import 'package:via/src/core/result.dart';
import 'package:via/src/features/pipeline.dart';
import 'package:via/src/features/retry.dart';

/// Type alias for the method function that executes HTTP requests
typedef ExecutorMethod<R extends ViaResult> =
    Future<R> Function(ViaRequest request);

/// Type alias for custom runner (e.g., isolate execution)
///
/// Example:
/// ```dart
/// // Run in isolate
/// final runner = (method, payload) => Isolate.run(() => method(payload));
/// ```
typedef Runner<R extends ViaResult> =
    Future<R> Function(ExecutorMethod<R> method, ViaRequest request);

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
class ViaExecutor<R extends ViaResult> {
  /// Creates a new Executor.
  ///
  /// [pipelines] - List of pipelines to run on each request
  /// [runner] - Custom runner for execution (e.g., isolate). If null, runs directly.
  const ViaExecutor({
    this.retry = const FetchRetry(),
    this.pipelines = const [],
    this.runner,
  });

  final FetchRetry retry;

  /// Pipelines to run on each request
  final List<ViaPipeline<R>> pipelines;

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
    ViaRequest request, {
    required ExecutorMethod<R> method,
    List<ViaPipeline<R>> pipelines = const [],
  }) async {
    final pipes = [...this.pipelines, ...pipelines];

    try {
      return retry.retry<R>(() => _executeOnce(request, method, pipes));
    } on ViaException catch (error) {
      for (final pipeline in pipes) {
        pipeline.onError(error);
      }

      rethrow;
    } catch (error, stackTrace) {
      final viaException = ViaException.custom(
        request: request,
        stackTrace: stackTrace,
        message: error.toString(),
      );

      for (final pipeline in pipes) {
        pipeline.onError(viaException);
      }

      throw viaException;
    }
  }

  /// Executes a single attempt through pipelines and runner.
  Future<R> _executeOnce(
    ViaRequest request,
    ExecutorMethod<R> method,
    List<ViaPipeline<R>> pipelines,
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

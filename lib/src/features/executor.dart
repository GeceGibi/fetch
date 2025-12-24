import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:via/src/core/request.dart';
import 'package:via/src/core/result.dart';
import 'package:via/src/features/pipelines/http_pipeline.dart';
import 'package:via/src/features/retry.dart';

Future<ViaResult> _defaultRunner(
  ExecutorMethod method,
  ViaRequest request,
) =>
    method(request);

/// Type alias for the method function that executes HTTP requests
typedef ExecutorMethod = Future<ViaResult> Function(ViaRequest request);

/// Type alias for custom runner (e.g., isolate execution)
///
/// Example:
/// ```dart
/// // Run in isolate
/// final runner = (method, payload) => Isolate.run(() => method(payload));
/// ```
typedef Runner = Future<ViaResult> Function(
    ExecutorMethod method, ViaRequest request);

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
/// final executor = ViaExecutor(
///   pipelines: [ViaLoggerPipeline()],
///   errorIf: (result) => result.response.statusCode >= 400,
/// );
/// ```
class ViaExecutor {
  /// Creates a new Executor.
  ///
  /// [pipelines] - List of pipelines to run on each request
  /// [runner] - Custom runner for execution (e.g., isolate). If null, runs directly.
  const ViaExecutor({
    this.retry = const ViaRetry(),
    this.pipelines = const [],
    this.runner = _defaultRunner,
    this.errorIf = _defaultErrorIf,
  });

  final ViaRetry retry;

  /// Pipelines to run on each request
  final List<ViaPipeline> pipelines;

  /// Custom runner for execution (e.g., for isolate-based execution)
  /// If null, the method is called directly
  final Runner runner;

  /// Optional validation logic to treat a successful network response as an error.
  /// Should return true if the result should be treated as an error,
  /// or false if the result is valid.
  /// Defaults to checking [ViaResult.isSuccess] (non-2xx status codes).
  final FutureOr<bool> Function(ViaResult result) errorIf;

  static bool _defaultErrorIf(ViaResult result) => !result.isSuccess;

  /// Executes the request through pipelines.
  ///
  /// [request] - Initial request payload
  /// [method] - The method to run the actual HTTP request
  /// [pipelines] - Additional pipelines for this specific request
  /// [runner] - Optional runner override for this specific execution.
  ///
  /// Returns the processed response after all pipelines have run.
  Future<ViaResult> execute(
    ViaRequest request, {
    required ExecutorMethod method,
    List<ViaPipeline> pipelines = const [],
    Runner? runner,
  }) async {
    final allPipelines = [...this.pipelines, ...pipelines];
    final activeRunner = request.isStream
        ? (ExecutorMethod executorMethod, ViaRequest viaRequest) =>
            executorMethod(viaRequest)
        : (runner ?? this.runner);

    try {
      return retry.retry(
        () => _executeOnce(request, method, allPipelines, activeRunner),
      );
    } on ViaException catch (error) {
      for (final pipeline in allPipelines) {
        pipeline.onError(error);
      }

      rethrow;
    } catch (error, stackTrace) {
      final viaException = ViaException.custom(
        request: request,
        stackTrace: stackTrace,
        message: error.toString(),
      );

      for (final pipeline in allPipelines) {
        pipeline.onError(viaException);
      }

      throw viaException;
    }
  }

  /// Executes a single attempt through pipelines and runner.
  Future<ViaResult> _executeOnce(
    ViaRequest request,
    ExecutorMethod method,
    List<ViaPipeline> pipelines,
    Runner activeRunner,
  ) async {
    var currentRequest = request;
    // 1. Pre-request pipelines - can modify payload or throw SkipRequest
    ViaResult? skipResponse;
    try {
      for (final pipeline in pipelines) {
        currentRequest = await pipeline.onRequest(currentRequest);
      }
    } on SkipRequest catch (skip) {
      skipResponse = skip.result;
    }

    // 2. Execute request (or use skip response from cache/etc)
    final ViaResult response;
    final stopWatch = Stopwatch()..start();

    /// skip request execution and use cached response
    if (skipResponse != null) {
      response = skipResponse;
    }

    /// real request execution
    else {
      var result = await activeRunner(method, currentRequest);

      // Handle streaming pipelines
      if (result.response is http.StreamedResponse) {
        var dataStream = (result.response as http.StreamedResponse).stream;

        for (final pipeline in pipelines) {
          dataStream = http.ByteStream(
            pipeline.onStream(currentRequest, dataStream),
          );
        }

        final streamedResponse = result.response as http.StreamedResponse;

        result = ViaResult(
          request: currentRequest,
          response: http.StreamedResponse(
            dataStream,
            streamedResponse.statusCode,
            contentLength: streamedResponse.contentLength,
            request: streamedResponse.request,
            headers: streamedResponse.headers,
            isRedirect: streamedResponse.isRedirect,
            persistentConnection: streamedResponse.persistentConnection,
            reasonPhrase: streamedResponse.reasonPhrase,
          ),
        );
      }
      response = result;
    }

    response.elapsed = stopWatch.elapsed;

    // 3. Post-response pipelines (same order)
    var processedResponse = response;
    for (final pipeline in pipelines) {
      processedResponse = await pipeline.onResult(processedResponse);
    }

    // 4. Custom validation
    if (await errorIf(processedResponse)) {
      throw ViaException.http(
        request: currentRequest,
        response: processedResponse.response,
        message: processedResponse.response.reasonPhrase ?? 'ErrorIfValidation',
      );
    }

    return processedResponse;
  }
}

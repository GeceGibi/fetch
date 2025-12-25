/// A comprehensive HTTP client library for Dart/Flutter applications.
///
/// This library provides a modern, type-safe HTTP client with built-in caching,
/// logging, and response transformation capabilities. It's designed to be easy
/// to use while providing powerful features for production applications.
library;

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:via/src/core/helpers.dart';
import 'package:via/src/core/request.dart';
import 'package:via/src/core/result.dart';
import 'package:via/src/features/cancel.dart';
import 'package:via/src/features/pipeline.dart';
import 'package:via/src/features/retry.dart';
import 'package:via/src/methods.dart';

export 'src/core/helpers.dart';
export 'src/core/request.dart';
export 'src/core/result.dart';
export 'src/features/cache.dart';
export 'src/features/cancel.dart';
export 'src/features/pipeline.dart';
export 'src/features/retry.dart';
export 'src/methods.dart';

/// Type alias for the method function that executes HTTP requests
typedef ExecutorMethod = Future<ViaBaseResult> Function(ViaRequest request);

/// Type alias for custom runner (e.g., isolate execution)
typedef Runner = Future<ViaBaseResult> Function(
    ExecutorMethod method, ViaRequest request);

Future<ViaBaseResult> _defaultRunner(
  ExecutorMethod method,
  ViaRequest request,
) =>
    method(request);

/// A comprehensive HTTP client with caching, logging, and request capabilities.
class Via<R extends ViaResult> with ViaMethods<R> {
  /// Creates a new Via instance.
  ///
  /// [base] - Base URI for all requests (optional)
  /// [timeout] - Request timeout duration (default: 30 seconds)
  /// [retry] - Retry logic configuration
  /// [pipelines] - Global pipelines for all requests
  /// [runner] - Custom runner for execution (e.g., isolate)
  /// [onError] - Global error handler for all errors
  /// [client] - Optional custom HTTP client to reuse
  Via({
    Uri? base,
    this.timeout = const Duration(seconds: 30),
    this.retry = const ViaRetry(),
    this.pipelines = const [],
    this.runner = _defaultRunner,
    this.onError,
    http.Client? client,
  }) : _customClient = client {
    if (base != null) {
      this.base = base;
    }
  }

  /// Global shared client for performance (connection pooling)
  static final http.Client _defaultClient = http.Client();

  /// Custom client if provided
  final http.Client? _customClient;

  /// Returns the client to use for this instance
  http.Client get _client => _customClient ?? _defaultClient;

  /// Base URI for all requests
  Uri base = Uri();

  /// Request timeout duration
  final Duration timeout;

  /// Global pipelines for all requests
  final List<ViaPipeline> pipelines;

  /// Retry logic configuration
  final ViaRetry retry;

  /// Custom runner for execution (e.g., for isolate-based execution)
  final Runner runner;

  /// Global error handler
  final void Function(ViaException error)? onError;

  /// Executes the HTTP request using the http package.
  ///
  /// [request] - The request payload containing all necessary information
  ///
  /// Returns a Future that completes with the HTTP response.
  Future<ViaBaseResult> _runMethod(ViaRequest request) async {
    final ViaRequest(:uri, :method, :body, :files, :headers, :cancelToken) =
        request;

    // Check if cancelled before starting
    if (cancelToken?.isCancelled ?? false) {
      throw ViaException.cancelled(request: request);
    }

    // For requests with cancellation, we use a fresh client to allow closing it.
    // For standard requests, we reuse the shared client for connection pooling.
    final httpClient = cancelToken != null ? http.Client() : _client;
    final http.BaseRequest httpRequest;

    if (files != null && files.isNotEmpty) {
      final multipartRequest = http.MultipartRequest(method.name, uri);

      if (body is Map) {
        multipartRequest.fields.addAll(
          body.map((key, value) => MapEntry(key.toString(), value.toString())),
        );
      }

      for (final entry in files.entries) {
        final file = entry.value;

        if (file.bytes != null) {
          multipartRequest.files.add(
            http.MultipartFile.fromBytes(
              entry.key,
              file.bytes!,
              filename: file.filename,
            ),
          );
        } else if (file.value != null) {
          multipartRequest.files.add(
            http.MultipartFile.fromString(
              entry.key,
              file.value!,
              filename: file.filename,
            ),
          );
        }
      }

      httpRequest = multipartRequest;
    } else if (body is Stream<List<int>>) {
      final streamedRequest = http.StreamedRequest(method.name, uri);

      body.listen(
        streamedRequest.sink.add,
        onError: (Object error, StackTrace stackTrace) {
          streamedRequest.sink.addError(error, stackTrace);
        },
        onDone: streamedRequest.sink.close,
        cancelOnError: true,
      );

      httpRequest = streamedRequest;
    } else {
      final standardRequest = http.Request(method.name, uri);
      if (body != null) {
        if (body is String) {
          standardRequest.body = body;
        } else if (body is List) {
          standardRequest.bodyBytes = body.cast<int>();
        } else if (body is Map) {
          standardRequest.bodyFields = body.cast<String, String>();
        } else {
          throw ArgumentError('Invalid request body "$body".');
        }
      }
      httpRequest = standardRequest;
    }

    if (headers != null) {
      httpRequest.headers.addAll(headers);
    }

    // Add cancel callback to close client immediately
    void onCancel() => httpClient.close();
    cancelToken?.addCallback(onCancel);

    try {
      // Start the request
      final streamedResponse = await httpClient
          .send(httpRequest)
          .timeout(
            timeout,
            onTimeout: () {
              throw ViaException.network(
                request: request,
                message: 'Request timeout',
              );
            },
          );

      // Check if cancelled after receiving response
      if (cancelToken?.isCancelled ?? false) {
        throw ViaException.cancelled(request: request);
      }

      if (request.isStream) {
        return ViaResultStream(response: streamedResponse, request: request);
      } else {
        final bufferedResponse = await http.Response.fromStream(
          streamedResponse,
        );

        // Create a "clean" response. We detach the original request object
        // because it often contains unsendable streams (like ByteStream).
        // Instead, we attach a lightweight dummy request to keep basic metadata.
        final cleanResponse = http.Response.bytes(
          bufferedResponse.bodyBytes,
          bufferedResponse.statusCode,
          headers: bufferedResponse.headers,
          persistentConnection: bufferedResponse.persistentConnection,
          isRedirect: bufferedResponse.isRedirect,
          reasonPhrase: bufferedResponse.reasonPhrase,
          request: http.Request(request.method.value, request.uri)
            ..headers.addAll(request.headers ?? {}),
        );

        return ViaResult(response: cleanResponse, request: request);
      }
    } on ViaException {
      rethrow;
    } catch (e, stackTrace) {
      // If client was closed due to cancellation
      if (cancelToken?.isCancelled ?? false) {
        throw ViaException.cancelled(request: request);
      }

      // Connection error
      throw ViaException.network(
        request: request,
        message: e.toString(),
        stackTrace: stackTrace,
      );
    } finally {
      cancelToken?.removeCallback(onCancel);
      // Only close the client if it was a temporary one created for cancellation
      if (cancelToken != null) {
        httpClient.close();
      }
    }
  }

  /// Internal worker method that handles all HTTP requests.
  ///
  /// This method:
  /// - Constructs the URI
  /// - Creates the payload
  /// - Delegates to executor for pipelines, execution, and retry
  /// - Applies transformation
  /// - Handles global error callback
  ///
  /// [method] - The HTTP method
  /// [endpoint] - The endpoint to request
  /// [headers] - HTTP headers
  /// [body] - Request body
  /// [queryParams] - Query parameters
  /// [cancelToken] - Optional token to cancel the request
  /// [pipelines] - Additional pipelines for this request
  /// [runner] - Optional runner override for this request
  /// [isStream] - Whether this request should be handled as a stream
  ///
  /// Returns a [Future] that completes with the [ViaBaseResult].
  Future<ViaBaseResult> worker(
    ViaMethod method, {
    required String endpoint,
    required ViaHeaders headers,
    Object? body,
    Map<String, ViaFile>? files,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
    Runner? runner,
    bool isStream = false,
  }) async {
    // ... existing URI logic ...
    final Uri uri;

    if (endpoint.startsWith('http')) {
      final parseUri = Uri.parse(endpoint);
      uri = parseUri.replace(
        queryParameters: ViaHelpers.mapStringy({
          ...parseUri.queryParameters,
          ...?queryParams,
        }),
      );
    } else {
      uri = base.replace(
        path: (base.path + endpoint).replaceAll(RegExp('//+'), '/'),
        queryParameters: ViaHelpers.mapStringy({
          ...base.queryParameters,
          ...?queryParams,
        }),
      );
    }

    final effectiveIsStream = isStream || body is Stream || cancelToken != null;

    final request = ViaRequest(
      uri: uri,
      body: body,
      files: files,
      method: method,
      headers: headers,
      cancelToken: cancelToken,
      isStream: effectiveIsStream,
    );

    final allPipelines = [...this.pipelines, ...pipelines];

    try {
      final activeRunner = effectiveIsStream
          ? (ExecutorMethod executorMethod, ViaRequest viaRequest) =>
              executorMethod(viaRequest)
          : (runner ?? this.runner);

      return await retry.retry(
        () => _executeOnce(request, _runMethod, allPipelines, activeRunner),
      );
    } on ViaException catch (error) {
      for (final pipeline in allPipelines) {
        pipeline.onError(error);
      }
      onError?.call(error);
      rethrow;
    } catch (error, stackTrace) {
      final viaError = ViaException.network(
        request: request,
        message: error.toString(),
        stackTrace: stackTrace,
      );

      for (final pipeline in allPipelines) {
        pipeline.onError(viaError);
      }
      onError?.call(viaError);
      throw viaError;
    }
  }

  /// Executes a single attempt through pipelines and runner.
  Future<ViaBaseResult> _executeOnce(
    ViaRequest request,
    ExecutorMethod method,
    List<ViaPipeline> pipelines,
    Runner activeRunner,
  ) async {
    var currentRequest = request;
    
    // 1. Pre-request pipelines - can modify payload or throw SkipRequest
    ViaBaseResult? skipResponse;

    /// pre-request pipelines
    try {
      for (final pipeline in pipelines) {
        currentRequest = await pipeline.onRequest(currentRequest);
      }
    } on SkipRequest catch (skip) {
      skipResponse = skip.result;
    }

    // 2. Execute request (or use skip response from cache/etc)
    ViaBaseResult response;
    final stopWatch = Stopwatch()..start();

    /// skip request execution and use cached response
    if (skipResponse != null) {
      response = skipResponse;
    }

    /// real request execution
    else {
      final result = await activeRunner(method, currentRequest);

      // Handle streaming pipelines
      if (result is ViaResultStream) {
        var dataStream = result.stream;

        for (final pipeline in pipelines) {
          dataStream = pipeline.onStream(currentRequest, dataStream);
        }

        response = ViaResultStream(
          request: currentRequest,
          response: http.StreamedResponse(
            dataStream,
            result.statusCode,
            contentLength: result.response.contentLength,
            request: result.response.request,
            headers: result.headers,
            isRedirect: result.response.isRedirect,
            persistentConnection: result.response.persistentConnection,
            reasonPhrase: result.response.reasonPhrase,
          ),
        );
      } else {
        response = result;
      }
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

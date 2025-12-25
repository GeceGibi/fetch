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
import 'package:via/src/features/executor.dart';
import 'package:via/src/features/pipelines/http_pipeline.dart';
import 'package:via/src/methods.dart';

export 'src/core/helpers.dart';
export 'src/core/request.dart';
export 'src/core/result.dart';
export 'src/features/cache.dart';
export 'src/features/cancel.dart';
export 'src/features/executor.dart';
export 'src/features/pipelines/http_pipeline.dart';
export 'src/features/pipelines/socket_pipeline.dart';
export 'src/features/retry.dart';
export 'src/features/socket.dart';
export 'src/methods.dart';

/// A comprehensive HTTP client with caching, logging, and request capabilities.
///
/// This class provides a modern HTTP client that supports:
/// - Built-in caching with configurable strategies
/// - Request/response logging
/// - Custom executors for platform-specific strategies
/// - Timeout handling
/// - Header building
/// - Response validation via pipelines (for business logic errors)
///
/// Example usage:
/// ```dart
/// final via = Via<ViaResult>(
///   base: Uri.parse('https://api.example.com'),
///   executor: ViaExecutor(
///     pipelines: [
///       ViaLoggerPipeline(),
///       ViaAuthPipeline(getToken: () => token),
///       ViaResponseValidatorPipeline(
///         validator: (result) => result.isSuccess ? null : 'Error',
///       ),
///     ],
///   ),
/// );
///
/// final response = await via.get('/users');
/// ```
class Via<R extends ViaResult> with ViaMethods<R> {
  /// Creates a new Via instance.
  ///
  /// [base] - Base URI for all requests (optional)
  /// [timeout] - Request timeout duration (default: 30 seconds)
  /// [executor] - Request executor with pipelines and retry logic
  /// [onError] - Global error handler for all errors
  /// [client] - Optional custom HTTP client to reuse
  Via({
    Uri? base,
    this.timeout = const Duration(seconds: 30),
    this.executor = const ViaExecutor(),
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

  /// Request executor (pipelines, runner, retry)
  final ViaExecutor executor;

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
      final streamedResponse = await httpClient.send(httpRequest).timeout(
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
        final bufferedResponse = await http.Response.fromStream(streamedResponse);
        return ViaResult(response: bufferedResponse, request: request);
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
    // Create URI
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

    // Create request
    final request = ViaRequest(
      uri: uri,
      body: body,
      files: files,
      method: method,
      headers: headers,
      cancelToken: cancelToken,
      isStream: isStream,
    );

    try {
      // Execute through executor (pipelines handle validation)
      final response = await executor.execute(
        request,
        method: _runMethod,
        pipelines: pipelines,
        runner: runner,
      );

      return response;
    } on ViaException catch (error) {
      onError?.call(error);
      rethrow;
    } catch (error, stackTrace) {
      final viaError = ViaException.network(
        request: request,
        message: error.toString(),
        stackTrace: stackTrace,
      );

      onError?.call(viaError);
      throw viaError;
    }
  }
}

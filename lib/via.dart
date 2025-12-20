// ignore_for_file: constant_identifier_names

/// A comprehensive HTTP client library for Dart/Flutter applications.
///
/// This library provides a modern, type-safe HTTP client with built-in caching,
/// logging, and response transformation capabilities. It's designed to be easy
/// to use while providing powerful features for production applications.
library via;

import 'dart:async';

import 'package:via/src/core/helpers.dart';
import 'package:via/src/core/request.dart';
import 'package:via/src/core/result.dart';
import 'package:via/src/features/cancel.dart';
import 'package:via/src/features/executor.dart';
import 'package:via/src/features/pipeline.dart';

import 'package:http/http.dart' as http;

export 'src/core/helpers.dart';
export 'src/core/request.dart';
export 'src/core/result.dart';
export 'src/features/cache.dart';
export 'src/features/cancel.dart';
export 'src/features/executor.dart';
export 'src/features/pipeline.dart';
export 'src/features/retry.dart';

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
/// final via = Via<ViaResponse>(
///   base: Uri.parse('https://api.example.com'),
///   executor: Executor(
///     pipelines: [
///       LogPipeline(),
///       AuthPipeline(getToken: () => token),
///       // Validate responses for business logic errors
///       ResponseValidatorPipeline(
///         validator: (response) {
///           final json = jsonDecode(response.response.body);
///           if (json['success'] == false) {
///             return json['message']; // Return error message
///           }
///           return null; // Valid response
///         },
///       ),
///     ],
///     maxAttempts: 3,
///     retryIf: (e) => e.statusCode == 401,
///   ),
/// );
///
/// final response = await via.get('/users');
/// ```
class Via<R extends ViaResult> {
  /// Creates a new Via instance.
  ///
  /// [base] - Base URI for all requests (optional)
  /// [timeout] - Request timeout duration (default: 30 seconds)
  /// [executor] - Request executor with pipelines and retry logic
  /// [onError] - Global error handler for all errors
  Via({
    Uri? base,
    this.timeout = const Duration(seconds: 30),
    this.executor = const ViaExecutor(),
    this.onError,
  }) {
    if (base != null) {
      this.base = base;
    }
  }

  /// Base URI for all requests
  Uri base = Uri();

  /// Request timeout duration
  final Duration timeout;

  /// Request executor (pipelines, runner, retry)
  final ViaExecutor<R> executor;

  /// Global error handler
  final void Function(ViaException error)? onError;

  /// Performs a GET request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline<R>> pipelines = const [],
  }) async {
    return _worker(
      'GET',
      endpoint: endpoint,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      pipelines: pipelines,
    );
  }

  /// Performs a HEAD request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> head(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline<R>> pipelines = const [],
  }) {
    return _worker(
      'HEAD',
      endpoint: endpoint,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      pipelines: pipelines,
    );
  }

  /// Performs a POST request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [body] - The request body
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> post(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline<R>> pipelines = const [],
  }) {
    return _worker(
      'POST',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      pipelines: pipelines,
    );
  }

  /// Performs a PUT request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [body] - The request body
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> put(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline<R>> pipelines = const [],
  }) {
    return _worker(
      'PUT',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      pipelines: pipelines,
    );
  }

  /// Performs a DELETE request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [body] - The request body
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> delete(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline<R>> pipelines = const [],
  }) {
    return _worker(
      'DELETE',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      pipelines: pipelines,
    );
  }

  /// Performs a PATCH request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [body] - The request body
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> patch(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline<R>> pipelines = const [],
  }) {
    return _worker(
      'PATCH',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      pipelines: pipelines,
    );
  }

  /// Executes the HTTP request using the http package.
  ///
  /// [request] - The request payload containing all necessary information
  ///
  /// Returns a Future that completes with the HTTP response.
  Future<R> _runMethod(ViaRequest request) async {
    final ViaRequest(:uri, :method, :body, :headers, :cancelToken) = request;

    // Check if cancelled before starting
    if (cancelToken?.isCancelled ?? false) {
      throw ViaException.cancelled(request: request);
    }

    final httpClient = http.Client();
    final httpRequest = http.Request(method, uri);

    if (headers != null) {
      httpRequest.headers.addAll(headers);
    }

    // Add cancel callback to close client immediately
    void onCancel() => httpClient.close();
    cancelToken?.addCallback(onCancel);

    if (body != null) {
      if (body is String) {
        httpRequest.body = body;
      } else if (body is List) {
        httpRequest.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        httpRequest.bodyFields = body.cast<String, String>();
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }

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

      // Check if cancelled during request
      if (cancelToken?.isCancelled ?? false) {
        throw ViaException.cancelled(request: request);
      }

      final response = await http.Response.fromStream(streamedResponse);

      // Check if cancelled after receiving response
      if (cancelToken?.isCancelled ?? false) {
        throw ViaException.cancelled(request: request);
      }

      return ViaResult(response: response, request: request) as R;
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
      httpClient.close();
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
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> _worker(
    String method, {
    required String endpoint,
    required ViaHeaders headers,
    Object? body,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
    List<ViaPipeline<R>> pipelines = const [],
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
      method: method,
      headers: headers,
      cancelToken: cancelToken,
    );

    try {
      // Execute through executor (pipelines handle validation)
      final response = await executor.execute(
        request,
        method: _runMethod,
        pipelines: pipelines,
      );

      // Transform
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

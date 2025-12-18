// ignore_for_file: constant_identifier_names

/// A comprehensive HTTP client library for Dart/Flutter applications.
///
/// This library provides a modern, type-safe HTTP client with built-in caching,
/// logging, and response transformation capabilities. It's designed to be easy
/// to use while providing powerful features for production applications.
library fetch;

import 'dart:async';

import 'package:fetch/src/core/helpers.dart';
import 'package:fetch/src/core/payload.dart';
import 'package:fetch/src/core/response.dart';
import 'package:fetch/src/features/cancel.dart';
import 'package:fetch/src/features/executor.dart';
import 'package:fetch/src/features/pipeline.dart';
import 'package:fetch/src/utils/exception.dart';
import 'package:http/http.dart' as http;

export 'src/core/helpers.dart';
export 'src/core/payload.dart';
export 'src/core/response.dart';
export 'src/features/cache.dart';
export 'src/features/cancel.dart';
export 'src/features/executor.dart';
export 'src/features/pipeline.dart';
export 'src/utils/exception.dart';

/// A comprehensive HTTP client with caching, logging, and request capabilities.
///
/// This class provides a modern HTTP client that supports:
/// - Built-in caching with configurable strategies
/// - Request/response logging
/// - Custom executors for platform-specific strategies
/// - Timeout handling
/// - Header building
///
/// Example usage:
/// ```dart
/// final fetch = Fetch<FetchResponse>(
///   base: Uri.parse('https://api.example.com'),
///   executor: Executor(
///     pipelines: [LogPipeline(), AuthPipeline()],
///     maxAttempts: 3,
///     retryIf: (e) => e.statusCode == 401,
///   ),
/// );
///
/// final response = await fetch.get('/users');
/// ```
class Fetch<R> {
  /// Creates a new Fetch instance.
  ///
  /// [base] - Base URI for all requests (optional)
  /// [timeout] - Request timeout duration (default: 30 seconds)
  /// [executor] - Request executor with pipelines and retry logic
  /// [onError] - Global error handler for all errors
  /// [transform] - Function to transform responses (receives response and payload)
  Fetch({
    Uri? base,
    this.timeout = const Duration(seconds: 30),
    this.executor = const Executor(),
    this.onError,
    FutureOr<R> Function(FetchResponse response)? transform,
  }) : transform = transform ?? ((response) => response as R) {
    if (base != null) {
      this.base = base;
    }
  }

  /// Base URI for all requests
  Uri base = Uri();

  /// Request timeout duration
  final Duration timeout;

  /// Request executor (pipelines, runner, retry)
  final Executor executor;

  /// Global error handler
  final void Function(FetchException error)? onError;

  /// Function to transform responses (default: returns response as R)
  final FutureOr<R> Function(FetchResponse response) transform;

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
    FetchHeaders headers = const {},
    CancelToken? cancelToken,
    List<FetchPipeline> pipelines = const [],
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
    FetchHeaders headers = const {},
    CancelToken? cancelToken,
    List<FetchPipeline> pipelines = const [],
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
    FetchHeaders headers = const {},
    CancelToken? cancelToken,
    List<FetchPipeline> pipelines = const [],
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
    FetchHeaders headers = const {},
    CancelToken? cancelToken,
    List<FetchPipeline> pipelines = const [],
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
    FetchHeaders headers = const {},
    CancelToken? cancelToken,
    List<FetchPipeline> pipelines = const [],
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
    FetchHeaders headers = const {},
    CancelToken? cancelToken,
    List<FetchPipeline> pipelines = const [],
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
  /// [payload] - The request payload containing all necessary information
  ///
  /// Returns a Future that completes with the HTTP response.
  Future<FetchResponse> _runMethod(FetchPayload payload) async {
    final FetchPayload(:uri, :method, :body, :headers, :cancelToken) = payload;

    // Check if cancelled before starting
    if (cancelToken?.isCancelled ?? false) {
      throw FetchException(
        payload: payload,
        type: FetchExceptionType.cancelled,
      );
    }

    final client = http.Client();
    final request = http.Request(method, uri);

    if (headers != null) {
      request.headers.addAll(headers);
    }

    // Add cancel callback to close client immediately
    void onCancel() => client.close();
    cancelToken?.addCallback(onCancel);

    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }

    try {
      // Start the request
      final streamedResponse = await client.send(request).timeout(
        timeout,
        onTimeout: () {
          throw FetchException(
            payload: payload,
            type: FetchExceptionType.network,
            message: 'Request timeout',
          );
        },
      );

      // Check if cancelled during request
      if (cancelToken?.isCancelled ?? false) {
        throw FetchException(
          payload: payload,
          type: FetchExceptionType.cancelled,
        );
      }

      final response = await http.Response.fromStream(streamedResponse);

      // Check if cancelled after receiving response
      if (cancelToken?.isCancelled ?? false) {
        throw FetchException(
          payload: payload,
          type: FetchExceptionType.cancelled,
        );
      }

      // Check for HTTP errors
      if (response.statusCode >= 400) {
        throw FetchException(
          payload: payload,
          type: FetchExceptionType.http,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }

      return FetchResponse(response, payload: payload);
    } on FetchException {
      rethrow;
    } catch (e, stackTrace) {
      // If client was closed due to cancellation
      if (cancelToken?.isCancelled ?? false) {
        throw FetchException(
          payload: payload,
          type: FetchExceptionType.cancelled,
        );
      }

      // Connection error
      throw FetchException(
        payload: payload,
        type: FetchExceptionType.network,
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      cancelToken?.removeCallback(onCancel);
      client.close();
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
    required FetchHeaders headers,
    Object? body,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
    List<FetchPipeline> pipelines = const [],
  }) async {
    // Create URI
    final Uri uri;

    if (endpoint.startsWith('http')) {
      final parseUri = Uri.parse(endpoint);
      uri = parseUri.replace(
        queryParameters: FetchHelpers.mapStringy({
          ...parseUri.queryParameters,
          ...?queryParams,
        }),
      );
    } else {
      uri = base.replace(
        path: (base.path + endpoint).replaceAll(RegExp('//+'), '/'),
        queryParameters: FetchHelpers.mapStringy({
          ...base.queryParameters,
          ...?queryParams,
        }),
      );
    }

    // Create payload
    final payload = FetchPayload(
      uri: uri,
      body: body,
      method: method,
      headers: headers,
      cancelToken: cancelToken,
    );

    try {
      // Execute through executor
      final response = await executor.execute(
        payload,
        method: _runMethod,
        pipelines: pipelines,
      );

      // Transform
      return await transform(response);
    } on FetchException catch (error) {
      onError?.call(error);
      rethrow;
    } catch (error, stackTrace) {
      final fetchError = FetchException(
        payload: payload,
        type: FetchExceptionType.network,
        error: error,
        stackTrace: stackTrace,
      );
      onError?.call(fetchError);
      throw fetchError;
    }
  }
}

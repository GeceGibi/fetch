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
import 'package:fetch/src/features/interceptor.dart';
import 'package:fetch/src/utils/exception.dart';
import 'package:http/http.dart' as http;

export 'src/core/helpers.dart';
export 'src/core/payload.dart';
export 'src/core/response.dart';
export 'src/features/cancel.dart';
export 'src/features/executor.dart';
export 'src/features/interceptor.dart';
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
/// );
///
/// final response = await fetch.get('/users');
/// ```
class Fetch<R> {
  /// Creates a new Fetch instance.
  ///
  /// [base] - Base URI for all requests (optional)
  /// [timeout] - Request timeout duration (default: 30 seconds)
  /// [interceptors] - List of interceptors (can include CacheInterceptor, DebounceInterceptor, etc.)
  /// [onError] - Global error handler for all errors
  /// [transform] - Function to transform responses (receives response and payload)
  /// [executor] - Request executor for platform-specific execution strategies
  Fetch({
    Uri? base,
    this.timeout = const Duration(seconds: 30),
    this.interceptors = const [],
    this.onError,
    this.transform,
    RequestExecutor? executor,
  }) : executor = executor ?? const DefaultExecutor() {
    if (base != null) {
      this.base = base;
    }
  }

  /// Base URI for all requests
  Uri base = Uri();

  /// Request timeout duration
  final Duration timeout;

  /// Request executor for platform-specific execution strategies
  final RequestExecutor executor;

  /// Interceptors
  final List<Interceptor> interceptors;

  /// Global error handler
  final void Function(FetchException error)? onError;

  /// Function to transform responses (receives response and payload)
  final FutureOr<R> Function(FetchResponse response, FetchPayload payload)?
      transform;

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
    List<Interceptor> interceptors = const [],
  }) async {
    return _worker(
      'GET',
      endpoint: endpoint,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      interceptors: interceptors,
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
    List<Interceptor> interceptors = const [],
  }) {
    return _worker(
      'HEAD',
      endpoint: endpoint,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      interceptors: interceptors,
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
    List<Interceptor> interceptors = const [],
  }) {
    return _worker(
      'POST',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      interceptors: interceptors,
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
    List<Interceptor> interceptors = const [],
  }) {
    return _worker(
      'PUT',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      interceptors: interceptors,
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
    List<Interceptor> interceptors = const [],
  }) {
    return _worker(
      'DELETE',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      interceptors: interceptors,
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
    List<Interceptor> interceptors = const [],
  }) {
    return _worker(
      'PATCH',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      interceptors: interceptors,
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
    final request = http.Request(method, uri)..headers.addAll(headers ?? {});

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
            type: FetchExceptionType.timeout,
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
          type: FetchExceptionType.httpError,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }

      return FetchResponse(response);
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
        type: FetchExceptionType.connectionError,
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
  /// This method orchestrates the entire request lifecycle including:
  /// - URI construction
  /// - Header merging
  /// - Interceptors (request)
  /// - Cache resolution
  /// - Debouncing
  /// - Retry logic
  /// - Request execution
  /// - Interceptors (response/error)
  /// - Response transformation
  /// - Logging
  ///
  /// [method] - The HTTP method
  /// [endpoint] - The endpoint to request
  /// [headers] - HTTP headers
  /// [body] - Request body
  /// [queryParams] - Query parameters
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> _worker(
    String method, {
    required String endpoint,
    required FetchHeaders headers,
    Object? body,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
    List<Interceptor> interceptors = const [],
  }) async {
    /// Create URI
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

    final mergedHeaders = FetchHelpers.mergeHeaders([
      headers,
    ]);

    // Initial payload
    var payload = FetchPayload(
      uri: uri,
      body: body,
      method: method,
      headers: mergedHeaders,
      cancelToken: cancelToken,
    );

    try {
      // Request interceptors - can modify payload or throw SkipRequest
      final allInterceptors = <Interceptor>[
        ...this.interceptors,
        ...interceptors,
      ];

      FetchResponse? skipResponse;
      try {
        for (final interceptor in allInterceptors) {
          payload = await interceptor.onRequest(payload);
        }
      } on SkipRequest catch (skip) {
        skipResponse = skip.response;
      }

      final stopwatch = Stopwatch()..start();

      // Execute request if not skipped (e.g., by cache)
      final FetchResponse fetchResponse;
      if (skipResponse != null) {
        fetchResponse = skipResponse;
      } else {
        fetchResponse = await executor.execute(
          payload,
          _runMethod,
        );
      }

      // Response interceptors
      var processedResponse = fetchResponse;
      for (final interceptor in allInterceptors) {
        processedResponse =
            await interceptor.onResponse(processedResponse, payload);
      }

      stopwatch.stop();

      // Transform
      final result = transform == null
          ? processedResponse as R
          : await transform!(processedResponse, payload);

      return result;
    } on FetchException catch (error) {
      final allInterceptors = <Interceptor>[
        ...this.interceptors,
        ...interceptors,
      ];
      // Error interceptors
      for (final interceptor in allInterceptors) {
        await interceptor.onError(error);
      }

      // Global error handler
      onError?.call(error);

      rethrow;
    } catch (error, stackTrace) {
      final fetchError = FetchException(
        payload: payload,
        type: FetchExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );

      // Error interceptors
      final allInterceptors = <Interceptor>[
        ...this.interceptors,
        ...interceptors,
      ];
      for (final interceptor in allInterceptors) {
        await interceptor.onError(fetchError);
      }

      // Global error handler
      onError?.call(fetchError);

      throw fetchError;
    }
  }
}

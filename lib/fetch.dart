// ignore_for_file: constant_identifier_names

/// A comprehensive HTTP client library for Dart/Flutter applications.
///
/// This library provides a modern, type-safe HTTP client with built-in caching,
/// logging, and response transformation capabilities. It's designed to be easy
/// to use while providing powerful features for production applications.
library fetch;

import 'dart:async';
import 'dart:convert';

import 'package:fetch/src/core/helpers.dart';
import 'package:fetch/src/core/logger.dart';
import 'package:fetch/src/core/payload.dart';
import 'package:fetch/src/core/response.dart';
import 'package:fetch/src/features/cache.dart';
import 'package:fetch/src/features/cancel.dart';
import 'package:fetch/src/features/debounce.dart';
import 'package:fetch/src/features/interceptor.dart';
import 'package:fetch/src/features/retry.dart';
import 'package:fetch/src/utils/exception.dart';
import 'package:http/http.dart' as http;

export 'src/core/helpers.dart';
export 'src/core/logger.dart';
export 'src/core/payload.dart';
export 'src/core/response.dart';
export 'src/features/cache.dart';
export 'src/features/cancel.dart';
export 'src/features/debounce.dart';
export 'src/features/interceptor.dart';
export 'src/features/retry.dart';
export 'src/utils/exception.dart';

/// Type alias for request override function
///
/// This function allows you to intercept and modify requests before they are sent.
/// It receives the payload and the original method function.
typedef FetchOverride = Future<FetchResponse> Function(
    FetchPayload payload, FetchMethod method);

/// A comprehensive HTTP client with caching, logging, and transformation capabilities.
///
/// This class provides a modern HTTP client that supports:
/// - Built-in caching with configurable strategies
/// - Request/response logging
/// - Response transformation
/// - Request overriding
/// - Timeout handling
/// - Header building
///
/// Example usage:
/// ```dart
/// final fetch = Fetch<Map<String, dynamic>>(
///   base: Uri.parse('https://api.example.com'),
///   transform: (response) => response.jsonBody as Map<String, dynamic>,
/// );
///
/// final data = await fetch.get('/users');
/// ```
class Fetch<R> with CacheFactory {
  /// Creates a new Fetch instance.
  ///
  /// [base] - Base URI for all requests (optional)
  /// [headerBuilder] - Function to build headers for each request
  /// [encoding] - Character encoding for requests/responses (default: utf8)
  /// [enableLogs] - Whether to enable request/response logging
  /// [timeout] - Request timeout duration (default: 30 seconds)
  /// [cacheOptions] - Cache configuration options
  /// [debounceOptions] - Debounce configuration options
  /// [retryOptions] - Retry configuration options
  /// [interceptors] - List of interceptors
  /// [onError] - Global error handler
  /// [transform] - Function to transform responses (required if R != FetchResponse)
  /// [override] - Function to override requests before sending
  Fetch({
    Uri? base,
    this.headerBuilder,
    this.encoding = utf8,
    this.timeout = const Duration(seconds: 30),
    this.cacheOptions = const CacheOptions(),
    this.debounceOptions = const DebounceOptions.disabled(),
    this.retryOptions = const RetryOptions.disabled(),
    this.interceptors = const [],
    this.onError,
    this.transform,
    this.override,
    bool enableLogs = true,
  }) : _enableLogs = enableLogs {
    if (base != null) {
      this.base = base;
    }

    if (transform == null && R != FetchResponse) {
      throw ArgumentError(
        'Fetch(...) must be Fetch<FetchResponse>(...) or transform method must be defined.',
      );
    }
  }

  /// Base URI for all requests
  Uri base = Uri();

  /// Request timeout duration
  final Duration timeout;

  /// Character encoding for requests/responses
  final Encoding encoding;

  /// Optional request override function
  final FetchOverride? override;

  /// Cache configuration options
  final CacheOptions cacheOptions;

  /// Debounce configuration options
  final DebounceOptions debounceOptions;

  /// Retry configuration options
  final RetryOptions retryOptions;

  /// Interceptors
  final List<Interceptor> interceptors;

  /// Global error handler
  final void Function(FetchException error, StackTrace stackTrace)? onError;

  /// Debounce manager
  final _debounceManager = DebounceManager();

  /// Function to build headers for each request
  final FutureOr<FetchHeaders> Function()? headerBuilder;

  /// Function to transform responses
  final FutureOr<R> Function(FetchResponse response)? transform;

  /// Stream controller for fetch events
  final _onFetchController = StreamController<R>.broadcast();

  /// List of all fetch logs for this instance
  final fetchLogs = <FetchLog>[];

  /// Stream of fetch events
  Stream<R> get onFetch => _onFetchController.stream;

  /// Internal logging method that handles request/response logging.
  ///
  /// This method creates a FetchLog entry and prints it to console.
  /// Only called when logging is enabled.
  ///
  /// [response] - The HTTP response to log
  /// [isCached] - Whether the response was retrieved from cache
  void _onLog(
    http.Response response,
    Object? postBody,
    Duration elapsed, {
    bool isCached = false,
  }) {
    final fetchLog = FetchLog(
      response,
      elapsed: elapsed,
      postBody: postBody,
      isCached: isCached,
    );

    fetchLogs.add(fetchLog);

    final pattern = RegExp('.{1,800}');
    for (final match in pattern.allMatches(fetchLog.toString().trim())) {
      // ignore: avoid_print
      print(match.group(0));
    }
  }

  /// Performs a GET request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cacheOptions] - Optional cache options for this request
  /// [debounceOptions] - Optional debounce options for this request
  /// [retryOptions] - Optional retry options for this request
  /// [enableLogs] - Whether to enable logging for this request
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
    DebounceOptions? debounceOptions,
    RetryOptions? retryOptions,
    bool? enableLogs,
    CancelToken? cancelToken,
  }) async {
    return _worker(
      'GET',
      endpoint: endpoint,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
      debounceOptions: debounceOptions,
      retryOptions: retryOptions,
      enableLogs: enableLogs,
      cancelToken: cancelToken,
    );
  }

  /// Performs a HEAD request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cacheOptions] - Optional cache options for this request
  /// [debounceOptions] - Optional debounce options for this request
  /// [retryOptions] - Optional retry options for this request
  /// [enableLogs] - Whether to enable logging for this request
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> head(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
    DebounceOptions? debounceOptions,
    RetryOptions? retryOptions,
    bool? enableLogs,
    CancelToken? cancelToken,
  }) {
    return _worker(
      'HEAD',
      endpoint: endpoint,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
      debounceOptions: debounceOptions,
      retryOptions: retryOptions,
      enableLogs: enableLogs,
      cancelToken: cancelToken,
    );
  }

  /// Performs a POST request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [body] - The request body
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cacheOptions] - Optional cache options for this request
  /// [debounceOptions] - Optional debounce options for this request
  /// [retryOptions] - Optional retry options for this request
  /// [enableLogs] - Whether to enable logging for this request
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> post(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
    DebounceOptions? debounceOptions,
    RetryOptions? retryOptions,
    bool? enableLogs,
    CancelToken? cancelToken,
  }) {
    return _worker(
      'POST',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
      debounceOptions: debounceOptions,
      retryOptions: retryOptions,
      enableLogs: enableLogs,
      cancelToken: cancelToken,
    );
  }

  /// Performs a PUT request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [body] - The request body
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cacheOptions] - Optional cache options for this request
  /// [debounceOptions] - Optional debounce options for this request
  /// [retryOptions] - Optional retry options for this request
  /// [enableLogs] - Whether to enable logging for this request
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> put(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
    DebounceOptions? debounceOptions,
    RetryOptions? retryOptions,
    bool? enableLogs,
    CancelToken? cancelToken,
  }) {
    return _worker(
      'PUT',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
      debounceOptions: debounceOptions,
      retryOptions: retryOptions,
      enableLogs: enableLogs,
      cancelToken: cancelToken,
    );
  }

  /// Performs a DELETE request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [body] - The request body
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cacheOptions] - Optional cache options for this request
  /// [debounceOptions] - Optional debounce options for this request
  /// [retryOptions] - Optional retry options for this request
  /// [enableLogs] - Whether to enable logging for this request
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> delete(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
    DebounceOptions? debounceOptions,
    RetryOptions? retryOptions,
    bool? enableLogs,
    CancelToken? cancelToken,
  }) {
    return _worker(
      'DELETE',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
      debounceOptions: debounceOptions,
      retryOptions: retryOptions,
      enableLogs: enableLogs,
      cancelToken: cancelToken,
    );
  }

  /// Performs a PATCH request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [body] - The request body
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cacheOptions] - Optional cache options for this request
  /// [debounceOptions] - Optional debounce options for this request
  /// [retryOptions] - Optional retry options for this request
  /// [enableLogs] - Whether to enable logging for this request
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> patch(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
    DebounceOptions? debounceOptions,
    RetryOptions? retryOptions,
    bool? enableLogs,
    CancelToken? cancelToken,
  }) {
    return _worker(
      'PATCH',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
      debounceOptions: debounceOptions,
      retryOptions: retryOptions,
      enableLogs: enableLogs,
      cancelToken: cancelToken,
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
        message: 'Request cancelled',
        type: FetchExceptionType.cancelled,
        uri: uri,
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
      final streamedResponse =
          await client.send(request).timeout(timeout, onTimeout: () {
        throw FetchException.timeout(uri, timeout);
      });

      // Check if cancelled during request
      if (cancelToken?.isCancelled ?? false) {
        throw FetchException(
          message: 'Request cancelled',
          type: FetchExceptionType.cancelled,
          uri: uri,
        );
      }

      final response = await http.Response.fromStream(streamedResponse);

      // Check if cancelled after receiving response
      if (cancelToken?.isCancelled ?? false) {
        throw FetchException(
          message: 'Request cancelled',
          type: FetchExceptionType.cancelled,
          uri: uri,
        );
      }

      // Check for HTTP errors
      if (response.statusCode >= 400) {
        throw FetchException.httpError(
          response.statusCode,
          uri,
          message: response.reasonPhrase,
          data: response.body,
        );
      }

      return FetchResponse(
        response,
        payload: payload,
        retryMethod: _runMethod,
      );
    } on FetchException {
      rethrow;
    } catch (e) {
      // If client was closed due to cancellation
      if (cancelToken?.isCancelled ?? false) {
        throw FetchException(
          message: 'Request cancelled',
          type: FetchExceptionType.cancelled,
          uri: uri,
        );
      }

      // Connection error
      throw FetchException.connectionError(uri, e);
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
  /// [cacheOptions] - Cache options
  /// [debounceOptions] - Debounce options
  /// [retryOptions] - Retry options
  /// [enableLogs] - Whether to enable logging
  /// [cancelToken] - Optional token to cancel the request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> _worker(
    String method, {
    required String endpoint,
    required FetchHeaders headers,
    Object? body,
    Map<String, dynamic>? queryParams,
    CacheOptions? cacheOptions,
    DebounceOptions? debounceOptions,
    RetryOptions? retryOptions,
    bool? enableLogs,
    CancelToken? cancelToken,
  }) async {
    try {
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
        await headerBuilder?.call() ?? {},
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

      // Request interceptors
      for (final interceptor in interceptors) {
        payload = await interceptor.onRequest(payload);
      }

      // Check cache
      final resolvedCache =
          resolveCache(uri, cacheOptions ?? this.cacheOptions);
      var response = resolvedCache?.response;

      final stopwatch = Stopwatch()..start();

      // Execute request if not cached
      final FetchResponse fetchResponse;

      if (response == null) {
        final resolvedDebounce = debounceOptions ?? this.debounceOptions;
        final resolvedRetry = retryOptions ?? this.retryOptions;

        // Debounce + Retry wrapper
        fetchResponse = await _debounceManager.debounce(
          uri.toString(),
          resolvedDebounce,
          () => _executeWithRetry(payload, resolvedRetry),
        );

        cache(fetchResponse, uri, cacheOptions ?? this.cacheOptions);
      } else {
        fetchResponse = response;
      }

      stopwatch.stop();

      // Response interceptors
      var finalResponse = fetchResponse;
      for (final interceptor in interceptors) {
        finalResponse = await interceptor.onResponse(finalResponse);
      }

      final result = switch (transform == null) {
        true => finalResponse as R,
        false => await transform!(finalResponse),
      };

      /// Log
      if (enableLogs ?? this.enableLogs) {
        _onLog(
          finalResponse.response,
          payload.body,
          stopwatch.elapsed,
          isCached: resolvedCache != null,
        );
      }

      _onFetchController.add(result);

      return result;
    } on FetchException catch (error, stackTrace) {
      // Error interceptors
      for (final interceptor in interceptors) {
        await interceptor.onError(error);
      }

      // Global error handler
      onError?.call(error, stackTrace);

      rethrow;
    } catch (error, stackTrace) {
      final fetchError = FetchException(
        message: error.toString(),
        type: FetchExceptionType.unknown,
        stackTrace: stackTrace,
      );

      // Error interceptors
      for (final interceptor in interceptors) {
        await interceptor.onError(fetchError);
      }

      // Global error handler
      onError?.call(fetchError, stackTrace);

      throw fetchError;
    }
  }

  /// Execute request with retry logic
  Future<FetchResponse> _executeWithRetry(
    FetchPayload payload,
    RetryOptions options,
  ) async {
    var attempt = 0;
    var delay = options.retryDelay;

    while (true) {
      attempt++;

      try {
        if (override != null) {
          return await override!(payload, _runMethod);
        } else {
          return await _runMethod(payload);
        }
      } on FetchException catch (e) {
        final shouldRetry =
            options.retryIf?.call(e) ?? RetryOptions.defaultRetryIf(e);

        if (!shouldRetry || attempt >= options.maxAttempts) {
          rethrow;
        }

        // Wait before retry
        await Future<void>.delayed(delay);
        delay = Duration(
          milliseconds:
              (delay.inMilliseconds * options.retryDelayFactor).round(),
        );
      }
    }
  }

  /// Clears the fetch logs.
  /// Whether to enable request/response logging
  bool _enableLogs = true;
  bool get enableLogs => _enableLogs;
  set enableLogs(bool value) {
    _enableLogs = value;

    if (!value) {
      fetchLogs.clear();
    }
  }

  /// Clears all debounce states.
  void clearDebounce() {
    _debounceManager.clear();
  }

  /// Clears debounce state for a specific endpoint.
  void clearDebounceForEndpoint(String endpoint) {
    _debounceManager.clearKey(endpoint);
  }

  /// Disposes the fetch instance and cleans up resources.
  ///
  /// This method should be called when the fetch instance is no longer needed
  /// to prevent memory leaks.
  void dispose() {
    _onFetchController.close();
    _debounceManager.clear();
  }
}

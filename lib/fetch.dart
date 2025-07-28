// ignore_for_file: constant_identifier_names

/// A comprehensive HTTP client library for Dart/Flutter applications.
///
/// This library provides a modern, type-safe HTTP client with built-in caching,
/// logging, and response transformation capabilities. It's designed to be easy
/// to use while providing powerful features for production applications.
library fetch;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

part 'cache.dart';
part 'logger.dart';
part 'helpers.dart';
part 'response.dart';

/// Type alias for HTTP headers map
typedef FetchHeaders = Map<String, String>;

/// Type alias for HTTP method function signature
typedef FetchMethod = Future<FetchResponse> Function(FetchPayload payload);

/// Represents the payload for an HTTP request.
///
/// This class encapsulates all the necessary information for making an HTTP request
/// including the URI, method, headers, and body.
class FetchPayload {
  /// Creates a new FetchPayload instance.
  ///
  /// [uri] - The target URI for the request
  /// [method] - The HTTP method (GET, POST, PUT, DELETE, etc.)
  /// [headers] - Optional HTTP headers
  /// [body] - Optional request body
  FetchPayload({
    required this.uri,
    required this.method,
    this.headers,
    this.body,
  });

  /// The target URI for the request
  final Uri uri;

  /// The HTTP method (GET, POST, PUT, DELETE, etc.)
  final String method;

  /// Optional request body
  final Object? body;

  /// Optional HTTP headers
  final FetchHeaders? headers;

  /// Creates a copy of this FetchPayload with the given fields replaced by new values.
  ///
  /// Returns a new FetchPayload instance with updated values.
  FetchPayload copyWith({
    Uri? uri,
    String? method,
    Object? body,
    FetchHeaders? headers,
  }) {
    return FetchPayload(
      uri: uri ?? this.uri,
      body: body ?? this.body,
      method: method ?? this.method,
      headers: headers ?? this.headers,
    );
  }

  @override
  String toString() {
    return 'FetchPayload(method: $method, uri: $uri, headers: $headers, body: $body)';
  }
}

/// Type alias for request override function
///
/// This function allows you to intercept and modify requests before they are sent.
/// It receives the payload and the original method function.
typedef FetchOverride = Future<FetchResponse> Function(
  FetchPayload payload,
  FetchMethod method,
);

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
  /// [transform] - Function to transform responses (required if R != FetchResponse)
  /// [override] - Function to override requests before sending
  /// [onLog] - Custom logging function for request/response events
  Fetch({
    Uri? base,
    this.headerBuilder,
    this.encoding = utf8,
    this.enableLogs = true,
    this.timeout = const Duration(seconds: 30),
    this.cacheOptions = const CacheOptions(),
    this.transform,
    this.override,
  }) {
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

  /// Whether to enable request/response logging
  final bool enableLogs;

  /// Request timeout duration
  final Duration timeout;

  /// Character encoding for requests/responses
  final Encoding encoding;

  /// Optional request override function
  final FetchOverride? override;

  /// Cache configuration options
  final CacheOptions cacheOptions;

  /// Function to build headers for each request
  final FutureOr<FetchHeaders> Function()? headerBuilder;

  /// Function to transform responses
  final FutureOr<R> Function(FetchResponse response)? transform;

  /// Stream controller for fetch events
  final _onFetchController = StreamController<R>.broadcast();

  /// List of all fetch logs for this instance
  final fetchLogs = <FetchLog>[];

  /// Internal logging method that handles request/response logging.
  ///
  /// This method creates a FetchLog entry and either calls the custom onLog function
  /// or prints the log to console with line wrapping.
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

    if (!enableLogs) {
      return;
    }

    final pattern = RegExp('.{1,800}');
    for (final match in pattern.allMatches(fetchLog.toString().trim())) {
      // ignore: avoid_print
      print(match.group(0));
    }
  }

  /// Stream of fetch events
  Stream<R> get onFetch => _onFetchController.stream;

  /// Performs a GET request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cacheOptions] - Optional cache options for this request
  /// [enableLogs] - Whether to enable logging for this request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
    bool? enableLogs,
  }) async {
    return _worker(
      'GET',
      endpoint: endpoint,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
      enableLogs: enableLogs,
    );
  }

  /// Performs a HEAD request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cacheOptions] - Optional cache options for this request
  /// [enableLogs] - Whether to enable logging for this request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> head(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
    bool? enableLogs,
  }) {
    return _worker(
      'HEAD',
      endpoint: endpoint,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
      enableLogs: enableLogs,
    );
  }

  /// Performs a POST request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [body] - The request body
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cacheOptions] - Optional cache options for this request
  /// [enableLogs] - Whether to enable logging for this request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> post(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
    bool? enableLogs,
  }) {
    return _worker(
      'POST',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
      enableLogs: enableLogs,
    );
  }

  /// Performs a PUT request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [body] - The request body
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cacheOptions] - Optional cache options for this request
  /// [enableLogs] - Whether to enable logging for this request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> put(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
    bool? enableLogs,
  }) {
    return _worker(
      'PUT',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
      enableLogs: enableLogs,
    );
  }

  /// Performs a DELETE request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [body] - The request body
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cacheOptions] - Optional cache options for this request
  /// [enableLogs] - Whether to enable logging for this request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> delete(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
    bool? enableLogs,
  }) {
    return _worker(
      'DELETE',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
      enableLogs: enableLogs,
    );
  }

  /// Performs a PATCH request.
  ///
  /// [endpoint] - The endpoint to request (can be full URL or relative path)
  /// [body] - The request body
  /// [queryParams] - Optional query parameters
  /// [headers] - Optional HTTP headers
  /// [cacheOptions] - Optional cache options for this request
  /// [enableLogs] - Whether to enable logging for this request
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> patch(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
    bool? enableLogs,
  }) {
    return _worker(
      'PATCH',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
      enableLogs: enableLogs,
    );
  }

  /// Executes the HTTP request using the http package.
  ///
  /// [payload] - The request payload containing all necessary information
  ///
  /// Returns a Future that completes with the HTTP response.
  Future<FetchResponse> _runMethod(FetchPayload payload) async {
    final FetchPayload(:uri, :method, :body, :headers) = payload;
    final request = http.Request(method, uri)..headers.addAll(headers ?? {});

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

    final response = await http.Response.fromStream(
      await request.send().timeout(timeout),
    );

    return FetchResponse(response, postBody: payload.body);
  }

  /// Internal worker method that handles all HTTP requests.
  ///
  /// This method orchestrates the entire request lifecycle including:
  /// - URI construction
  /// - Header merging
  /// - Cache resolution
  /// - Request execution
  /// - Response transformation
  /// - Logging
  ///
  /// [method] - The HTTP method
  /// [endpoint] - The endpoint to request
  /// [headers] - HTTP headers
  /// [body] - Request body
  /// [queryParams] - Query parameters
  /// [cacheOptions] - Cache options
  /// [enableLogs] - Whether to enable logging
  ///
  /// Returns a Future that completes with the transformed response.
  Future<R> _worker(
    String method, {
    required String endpoint,
    required FetchHeaders headers,
    Object? body,
    Map<String, dynamic>? queryParams,
    CacheOptions? cacheOptions,
    bool? enableLogs,
  }) async {
    /// Create uri
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

    final mergedHeaders = FetchHelpers.mergeHeaders(
      [await headerBuilder?.call() ?? {}, headers],
    );

    final resolvedCache = resolveCache(uri, cacheOptions ?? this.cacheOptions);
    var response = resolvedCache?.response;

    final payload = FetchPayload(
      uri: uri,
      body: body,
      method: method,
      headers: mergedHeaders,
    );

    final stopwatch = Stopwatch()..start();

    /// Override
    if (response == null) {
      if (override != null) {
        response = await override!(payload, _runMethod);
      }

      /// Request
      else {
        response = await _runMethod(payload);
      }

      cache(response, uri, cacheOptions ?? this.cacheOptions);
    }

    stopwatch.stop();

    final result = switch (transform == null) {
      true => response as R,
      false => await transform!(response),
    };

    /// Log
    _onLog(
      response.response,
      payload.body,
      stopwatch.elapsed,
      isCached: resolvedCache != null,
    );

    _onFetchController.add(result);

    return result;
  }

  /// Disposes the fetch instance and cleans up resources.
  ///
  /// This method should be called when the fetch instance is no longer needed
  /// to prevent memory leaks.
  void dispose() {
    _onFetchController.close();
  }
}

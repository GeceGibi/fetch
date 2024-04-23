// ignore_for_file: constant_identifier_names

library fetch;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

part 'cache.dart';
part 'logger.dart';
part 'helpers.dart';
part 'response.dart';

typedef MethodWithBody = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
});

typedef MethodJustGetter = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
});

class FetchOverride {
  const FetchOverride({
    this.post,
    this.get,
    this.delete,
    this.head,
    this.patch,
    this.put,
  });

  final Future<http.Response> Function(
    MethodWithBody method,
    Uri uri,
    Object? body,
    Map<String, String> headers,
  )? post;

  final Future<http.Response> Function(
    MethodWithBody method,
    Uri uri,
    Object? body,
    Map<String, String> headers,
  )? delete;

  final Future<http.Response> Function(
    MethodWithBody method,
    Uri uri,
    Object? body,
    Map<String, String> headers,
  )? put;

  final Future<http.Response> Function(
    MethodWithBody method,
    Uri uri,
    Object? body,
    Map<String, String> headers,
  )? patch;

  final Future<http.Response> Function(
    MethodJustGetter method,
    Uri uri,
    Map<String, String> headers,
  )? get;

  final Future<http.Response> Function(
    MethodJustGetter method,
    Uri uri,
    Map<String, String> headers,
  )? head;
}

typedef Handler<R extends FetchResponse> = FutureOr<R> Function(
  HttpResponse? response,
  Object? error,
  Uri uri,
);

bool _shouldRequest(Uri uri, Map<String, String> headers) => true;
Map<String, String> _defaultHeaderBuilder() => <String, String>{};

class Fetch<R extends FetchResponse> with CacheFactory, FetchLogger {
  Fetch({
    required this.base,
    required this.handler,
    this.headerBuilder = _defaultHeaderBuilder,
    this.timeout = const Duration(seconds: 30),
    this.afterRequest,
    this.beforeRequest,
    this.shouldRequest = _shouldRequest,
    this.enableLogs = true,
    this.cacheOptions = const CacheOptions(),
    this.overrides = const FetchOverride(),
  }) {
    isLogsEnabled = enableLogs;
  }

  ///
  Uri base;

  final bool enableLogs;
  final Duration timeout;

  final Handler<R> handler;
  final FetchOverride overrides;
  final CacheOptions cacheOptions;
  final FutureOr<Map<String, String>> Function() headerBuilder;

  /// Streams
  late final Stream<FetchLog> onFetchSuccess = _onFetchController.stream;
  late final Stream<FetchLog> onFetchError = _onErrorController.stream;

  /// Lifecycle
  final FutureOr<void> Function(Uri uri)? beforeRequest;
  final FutureOr<void> Function(HttpResponse? response, Object? error)?
      afterRequest;
  final FutureOr<bool> Function(Uri uri, Map<String, String> headers)
      shouldRequest;

  /// GET
  Future<R> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
    CacheOptions? cacheOptions,
  }) =>
      _worker('GET', endpoint, null, queryParams, headers, cacheOptions);

  Future<R> head(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
    CacheOptions? cacheOptions,
  }) =>
      _worker('HEAD', endpoint, null, queryParams, headers, cacheOptions);

  /// POST
  Future<R> post(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
    CacheOptions? cacheOptions,
  }) {
    return _worker(
      'POST',
      endpoint,
      body,
      queryParams,
      headers,
      cacheOptions,
    );
  }

  Future<R> put(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
    CacheOptions? cacheOptions,
  }) {
    return _worker(
      'PUT',
      endpoint,
      body,
      queryParams,
      headers,
      cacheOptions,
    );
  }

  Future<R> delete(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
    CacheOptions? cacheOptions,
  }) {
    return _worker(
      'DELETE',
      endpoint,
      body,
      queryParams,
      headers,
      cacheOptions,
    );
  }

  Future<R> patch(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
    CacheOptions? cacheOptions,
  }) {
    return _worker(
      'PATCH',
      endpoint,
      body,
      queryParams,
      headers,
      cacheOptions,
    );
  }

  Future<R> _worker(
    String type,
    String path,
    Object? body,
    Map<String, dynamic>? queryParams,
    Map<String, String> headers,
    CacheOptions? cacheOptions,
  ) async {
    final completer = Completer<R>();
    final stopwatch = Stopwatch()..start();

    /// Create uri
    final Uri uri;

    if (path.startsWith('http')) {
      uri = Uri.parse(path).replace(
        queryParameters: FetchHelpers.mapStringy(queryParams),
      );
    } else {
      uri = base.replace(
        path: (base.path + path).replaceAll(RegExp('//+'), '/'),
        queryParameters: FetchHelpers.mapStringy(queryParams),
      );
    }

    /// Make
    try {
      final mergedHeaders = FetchHelpers.mergeHeaders(
        [await headerBuilder(), headers],
      );

      if (!(await shouldRequest(uri, mergedHeaders))) {
        return handler(null, 'shouldRequest() not passed', uri);
      }

      await beforeRequest?.call(uri);

      // ignore: no_leading_underscores_for_local_identifiers
      final _cacheOptions = cacheOptions ?? this.cacheOptions;
      final cached = isCached(uri, _cacheOptions);

      final HttpResponse response;

      if (cached) {
        response = resolveCache(uri, _cacheOptions)!.response;
      }

      ///
      /// Get request
      else {
        // final client = HttpClient();

        // final request = await client.openUrl(type, uri);

        // if (body != null) {
        //   request.write(body);
        // }

        // for (final header in headers.entries) {
        //   request.headers.set(header.key, header.value);
        // }

        // final _response = await request.close();
        // final bytes = await _response.fold<List<int>>(
        //   [],
        //   (previous, element) => [...previous, ...element],
        // );

        // print(_response.statusCode);

        // print(utf8.decode(bytes));

        response = await switch (type) {
          /// Post
          'POST' => overrides.post != null
              ? overrides.post!(http.post, uri, body, mergedHeaders)
              : http
                  .post(uri, body: body, headers: mergedHeaders)
                  .timeout(timeout),

          /// Get
          'GET' => overrides.get != null
              ? overrides.get!(http.get, uri, mergedHeaders)
              : http.get(uri, headers: mergedHeaders).timeout(timeout),

          /// Delete
          'DELETE' => overrides.delete != null
              ? overrides.delete!(http.delete, uri, body, mergedHeaders)
              : http.delete(uri, headers: mergedHeaders, body: body),

          /// Put
          'PUT' => overrides.put != null
              ? overrides.put!(http.put, uri, body, mergedHeaders)
              : http.put(uri, headers: mergedHeaders, body: body),

          // Head
          'HEAD' => overrides.head != null
              ? overrides.head!(http.head, uri, mergedHeaders)
              : http.head(uri, headers: mergedHeaders),

          // Patch
          'PATCH' => overrides.patch != null
              ? overrides.patch!(http.patch, uri, body, mergedHeaders)
              : http.patch(uri, headers: mergedHeaders, body: body),

          ///
          _ => throw Exception('Unsupported type $type')
        };

        cache(response, uri, _cacheOptions);
      }

      stopwatch.stop();

      /// Log
      _log(response, stopwatch.elapsed, postBody: body, isCached: cached);

      /// Complete
      completer.complete(handler(response, null, uri));

      /// Callbacks
      await afterRequest?.call(response, null);
    } catch (error, trace) {
      /// Log
      _logError(error, trace);

      /// Complete
      completer.complete(handler(null, error, uri));

      /// Callback
      await afterRequest?.call(null, error);
    }

    return completer.future;
  }
}

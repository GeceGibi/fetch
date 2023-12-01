// ignore_for_file: no_leading_underscores_for_local_identifiers, constant_identifier_names

library fetch;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

part 'cache.dart';
part 'logger.dart';
part 'helpers.dart';
part 'response.dart';

enum FetchType {
  POST,
  GET,
}

typedef PostMethod = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
});

typedef GetMethod = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
});

class FetchOverride {
  const FetchOverride({this.post, this.get});

  final Future<http.Response> Function(
    PostMethod method,
    Uri uri,
    Object? body,
    Map<String, String> headers,
  )? post;

  final Future<http.Response> Function(
    GetMethod method,
    Uri uri,
    Map<String, String> headers,
  )? get;
}

typedef Handler<R extends FetchResponse> = FutureOr<R> Function(
  HttpResponse? response,
  Object? error,
  Uri uri,
);

bool _shouldRequest(Uri uri, Map<String, String> headers) => true;
Map<String, dynamic> _defaultHeaderBuilder() => {};

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
  String base;

  final bool enableLogs;
  final Duration timeout;

  final Handler<R> handler;
  final FetchOverride overrides;
  final CacheOptions cacheOptions;
  final FutureOr<Map<String, dynamic>> Function() headerBuilder;

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
  }) {
    return _worker(
      FetchType.GET,
      endpoint,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
    );
  }

  /// POST
  Future<R> post(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
    CacheOptions? cacheOptions,
  }) {
    return _worker(
      FetchType.POST,
      endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cacheOptions: cacheOptions,
    );
  }

  Future<R> _worker(
    FetchType type,
    String endpoint, {
    Object? body,
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
    CacheOptions? cacheOptions,
  }) async {
    final completer = Completer<R>();
    final stopwatch = Stopwatch()..start();

    /// Create uri
    final uri = Uri.parse(
      endpoint.startsWith('http') ? endpoint : base + endpoint,
    ).replace(queryParameters: FetchHelpers.mapStringy(queryParams));

    /// Make
    try {
      final mergedHeaders = FetchHelpers.mergeHeaders(
        [await headerBuilder(), headers],
      );

      if (!(await shouldRequest(uri, mergedHeaders))) {
        return handler(null, 'shouldRequest() not passed', uri);
      }

      await beforeRequest?.call(uri);

      final _cacheOptions = cacheOptions ?? this.cacheOptions;
      final cached = isCached(uri, _cacheOptions);

      final HttpResponse response;

      if (cached) {
        response = resolveCache(uri, _cacheOptions)!.response;
      }

      ///
      /// Get request
      else {
        response = switch (type) {
          /// Post
          FetchType.POST => overrides.post != null
              ? await overrides.post!(http.post, uri, body, mergedHeaders)
              : await http
                  .post(uri, body: body, headers: mergedHeaders)
                  .timeout(timeout),

          /// Get
          FetchType.GET => overrides.get != null
              ? await overrides.get!(http.get, uri, mergedHeaders)
              : await http.get(uri, headers: mergedHeaders).timeout(timeout),
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

// ignore_for_file: no_leading_underscores_for_local_identifiers

library fetch;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:http/http.dart' as http;

part 'cache.dart';
part 'logger.dart';
part 'helpers.dart';
part 'response.dart';

typedef PostMethod = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
});

typedef GetMethod = Future<http.Response> Function(
  Uri url, {
  Map<String, String>? headers,
  Encoding? encoding,
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

class Fetch<R extends FetchResponse> {
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
    this.encoding = utf8,
    this.overrides = const FetchOverride(),
  });

  ///
  String base;

  final bool enableLogs;
  final Encoding encoding;
  final CacheOptions cacheOptions;

  final Duration timeout;
  final FutureOr<Map<String, dynamic>> Function() headerBuilder;
  final Handler<R> handler;

  late final logger = FetchLogger(enableLogs, encoding: encoding);
  final cacheFactory = CacheFactory();

  final FetchOverride overrides;

  /// Streams
  late final Stream<FetchLog> onFetchSuccess = logger._onFetchController.stream;
  late final Stream<FetchLog> onFetchError = logger._onErrorController.stream;

  /// Lifecycle
  final FutureOr<void> Function(Uri uri)? beforeRequest;
  final FutureOr<void> Function(HttpResponse? response, Object? error)?
      afterRequest;
  final FutureOr<bool> Function(Uri uri, Map<String, String> headers)
      shouldRequest;

  Future<R> get(
    String endpoint, {
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

    /// Make request
    try {
      final mergedHeaders = FetchHelpers.mergeHeaders(
        [await headerBuilder(), headers],
      );

      if (!(await shouldRequest(uri, mergedHeaders))) {
        return handler(null, 'shouldRequest() not passed', uri);
      }

      await beforeRequest?.call(uri);

      final HttpResponse response;
      final _cacheOptions = cacheOptions ?? this.cacheOptions;
      final isCached = cacheFactory.isCached(uri, _cacheOptions);

      if (isCached) {
        response = cacheFactory.resolve(uri, _cacheOptions)!.response;
      } else {
        if (overrides.get != null) {
          response = await overrides.get!(http.post, uri, mergedHeaders);
        } else {
          response = await Isolate.run(() {
            return http.get(uri, headers: mergedHeaders).timeout(timeout);
          });
        }

        cacheFactory.cache(response, uri, _cacheOptions);
      }

      stopwatch.stop();

      /// Log
      logger._log(response, stopwatch.elapsed, isCached: isCached);

      /// Complete
      completer.complete(handler(response, null, uri));

      /// Callbacks
      await afterRequest?.call(response, null);
    } catch (error, trace) {
      /// Log
      logger._logError(error, trace);

      /// Complete
      completer.complete(handler(null, error, uri));

      /// Callback
      await afterRequest?.call(null, error);
    }

    return completer.future;
  }

  Future<R> post(
    String endpoint,
    Object? body, {
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

      final HttpResponse response;
      final _cacheOptions = cacheOptions ?? this.cacheOptions;
      final isCached = cacheFactory.isCached(uri, _cacheOptions);

      if (isCached) {
        response = cacheFactory.resolve(uri, _cacheOptions)!.response;
      } else {
        if (overrides.post != null) {
          response = await overrides.post!(http.post, uri, body, mergedHeaders);
        } else {
          response = await Isolate.run(() => http
              .post(uri, body: body, headers: mergedHeaders)
              .timeout(timeout));
        }

        cacheFactory.cache(response, uri, _cacheOptions);
      }

      stopwatch.stop();

      /// Log
      logger._log(
        response,
        stopwatch.elapsed,
        postBody: body,
        isCached: isCached,
      );

      /// Complete
      completer.complete(handler(response, null, uri));

      /// Callbacks
      await afterRequest?.call(response, null);
    } catch (error, trace) {
      /// Log
      logger._logError(error, trace);

      /// Complete
      completer.complete(handler(null, error, uri));

      /// Callback
      await afterRequest?.call(null, error);
    }

    return completer.future;
  }
}

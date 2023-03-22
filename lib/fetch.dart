// ignore_for_file: no_leading_underscores_for_local_identifiers

library fetch;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

part 'cache.dart';
part 'logger.dart';
part 'helpers.dart';
part 'response.dart';

bool _shouldRequest(Uri uri, Map<String, String> headers) => true;
Map<String, dynamic> _defaultHeaderBuilder() => {};

class Fetch<R extends FetchResponseBase> {
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
  });

  ///
  String base;

  final bool enableLogs;
  final CacheOptions cacheOptions;

  final Duration timeout;
  final FutureOr<Map<String, dynamic>> Function() headerBuilder;
  final R Function<T>(HttpResponse? response, Object? error, Uri? uri) handler;

  late final logger = FetchLogger(enableLogs);
  final cacheFactory = CacheFactory();

  /// Streams
  late final Stream<FetchLog> onFetchSuccess = logger._onFetchController.stream;
  late final Stream<FetchLog> onFetchError = logger._onErrorController.stream;

  /// Lifecycle
  final FutureOr<void> Function(Uri uri)? beforeRequest;
  final FutureOr<void> Function(HttpResponse? response, Object? error)?
      afterRequest;
  final FutureOr<bool> Function(Uri uri, Map<String, String> headers)
      shouldRequest;

  Future<R> get<T>(
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
        response = await http.get(uri, headers: mergedHeaders).timeout(timeout);
        cacheFactory.cache(response, uri, _cacheOptions);
      }

      stopwatch.stop();

      /// Log
      logger._log(response, stopwatch.elapsed, isCached: isCached);

      /// Complete
      completer.complete(handler<T>(response, null, uri));

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
        response = await http
            .post(uri, body: body, headers: mergedHeaders)
            .timeout(timeout);

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

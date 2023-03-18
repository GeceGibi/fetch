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

class Fetch {
  Fetch({
    required this.base,
    this.headers = const {},
    this.handler,
    this.timeout = const Duration(seconds: 30),
    this.afterRequest,
    this.beforeRequest,
    this.shouldRequest = _shouldRequest,
    this.enableLogs = true,
    this.cacheOptions = const FetchCacheOptions(),
  });

  ///
  String base;

  final bool enableLogs;
  final FetchCacheOptions cacheOptions;

  final Duration timeout;
  final Map<String, dynamic> headers;

  final FetchResponse<T> Function<T>(
    HttpResponse? response,
    Object? error,
    Uri? uri,
  )? handler;

  final logger = FetchLogger();
  final cacheFactory = FetchCacheFactory();

  /// Streams
  late final Stream<FetchLog> onFetchSuccess = logger._onFetchController.stream;
  late final Stream<FetchLog> onFetchError = logger._onErrorController.stream;

  /// Lifecycle
  final void Function(Uri uri)? beforeRequest;
  final void Function(HttpResponse? response, Object? error)? afterRequest;
  final FutureOr<bool> Function(Uri uri, Map<String, String> headers)
      shouldRequest;

  Future<FetchResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
    FetchCacheOptions? cacheOptions,
  }) async {
    final completer = Completer<FetchResponse<T>>();
    final stopwatch = Stopwatch();

    /// Make request
    try {
      /// Create uri
      final uri = Uri.parse(
        endpoint.startsWith('http') ? endpoint : base + endpoint,
      ).replace(queryParameters: FetchHelpers.mapStringy(queryParams));

      final mergedHeaders = FetchHelpers.mergeHeaders([this.headers, headers]);

      if (!(await shouldRequest(uri, mergedHeaders))) {
        return const FetchResponse.error(null);
      }

      beforeRequest?.call(uri);
      stopwatch.start();

      final http.Response response;
      final _cacheOptions = cacheOptions ?? this.cacheOptions;
      final isCached = cacheFactory.isCached(uri, _cacheOptions);

      if (isCached) {
        response = cacheFactory.resolve(uri, _cacheOptions)!.response;
      } else {
        response = await http.get(uri, headers: mergedHeaders).timeout(
              timeout,
            );

        cacheFactory.cache(response, uri, _cacheOptions);
      }

      stopwatch.stop();

      completer.complete(
        _responseHandler(
          response,
          isCached: isCached,
          stopwatch: stopwatch,
          uri: uri,
        ),
      );

      afterRequest?.call(response, null);
    } catch (error, stackTrace) {
      completer.complete(
        _responseHandler(
          null,
          error: error,
          stackTrace: stackTrace,
        ),
      );

      afterRequest?.call(null, error);
    }

    return completer.future;
  }

  Future<FetchResponse<T>> post<T>(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
    FetchCacheOptions? cacheOptions,
  }) async {
    final completer = Completer<FetchResponse<T>>();
    final stopwatch = Stopwatch();

    /// Make
    try {
      /// Create uri
      final uri = Uri.parse(
        endpoint.startsWith('http') ? endpoint : base + endpoint,
      ).replace(queryParameters: FetchHelpers.mapStringy(queryParams));

      final mergedHeaders = FetchHelpers.mergeHeaders([this.headers, headers]);

      if (!(await shouldRequest(uri, mergedHeaders))) {
        return const FetchResponse.error(null);
      }

      beforeRequest?.call(uri);
      stopwatch.start();

      final http.Response response;
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

      completer.complete(
        _responseHandler(
          response,
          isCached: isCached,
          stopwatch: stopwatch,
          postBody: body,
          uri: uri,
        ),
      );

      afterRequest?.call(response, null);
    } catch (error, stackTrace) {
      completer.complete(
        _responseHandler(
          null,
          error: error,
          stackTrace: stackTrace,
        ),
      );

      afterRequest?.call(null, error);
    }

    return completer.future;
  }

  FetchResponse<T> _responseHandler<T>(
    HttpResponse? response, {
    StackTrace? stackTrace,
    Stopwatch? stopwatch,
    Object? error,
    Object? postBody,
    Uri? uri,
    bool isCached = false,
  }) {
    if (enableLogs) {
      if (response == null) {
        logger._logError(error, stackTrace);
      } else {
        logger._log(
          response,
          stopwatch!.elapsed,
          postBody: postBody,
          isCached: isCached,
        );
      }
    }

    if (response == null) {
      if (handler != null) {
        return handler!(null, error, uri);
      } else {
        return FetchResponse<T>.error('$error');
      }
    }

    if (handler != null) {
      return handler!(response, error, uri);
    }

    return FetchResponse<T>.success(
      data: FetchHelpers.handleResponseBody(response),
      isSuccess: FetchHelpers.isSuccess(response.statusCode),
      message: response.reasonPhrase ?? error.toString(),
    );
  }
}

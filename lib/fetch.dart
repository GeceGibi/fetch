// ignore_for_file: constant_identifier_names

library fetch;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

part 'cache.dart';
part 'logger.dart';
part 'helpers.dart';
part 'response.dart';

typedef FetchHeaders = Map<String, String>;
typedef FetchMethod = Future<FetchResponse> Function(FetchPayload payload);

class FetchPayload {
  FetchPayload({
    required this.uri,
    required this.type,
    this.headers,
    this.body,
  });

  Uri uri;
  String type;
  Object? body;
  FetchHeaders? headers;

  FetchPayload copyWith({
    Uri? uri,
    String? type,
    Object? body,
    FetchHeaders? headers,
  }) {
    return FetchPayload(
      uri: uri ?? this.uri,
      type: type ?? this.type,
      body: body ?? this.type,
      headers: headers ?? this.headers,
    );
  }

  @override
  String toString() {
    return 'FetchPayload(type: $type, uri: $uri, headers: $headers, body: $body)';
  }
}

typedef FetchOverride = Future<FetchResponse> Function(
  FetchPayload payload,
  FetchMethod method,
);

class Fetch<R> with CacheFactory, FetchLogger {
  Fetch({
    Uri? base,
    this.headerBuilder,
    this.encoding = systemEncoding,
    this.enableLogs = true,
    this.timeout = const Duration(seconds: 30),
    this.cacheOptions = const CacheOptions(),
    this.transform,
    this.override,
  }) {
    if (base != null) {
      this.base = base;
    }

    _isLogsEnabled = enableLogs;
  }

  ///
  Uri base = Uri();

  final bool enableLogs;
  final Duration timeout;
  final Encoding encoding;

  final FetchOverride? override;
  final CacheOptions cacheOptions;
  final FutureOr<FetchHeaders> Function()? headerBuilder;
  final FutureOr<R> Function(FetchResponse response)? transform;

  final _onFetchController = StreamController<R>.broadcast();
  // final cancelledResponse = FetchResponse(
  //   '',
  //   600,
  //   reasonPhrase: 'Request cancelled from "shouldRequest"',
  // );

  /// Streams
  // late final Stream<FetchResponse> onFetchSuccess = _onFetchController.stream;

  /// GET
  Future<R> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
  }) async {
    return _worker('GET', endpoint, null, queryParams, headers, cacheOptions);
  }

  Future<R> head(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
  }) =>
      _worker('HEAD', endpoint, null, queryParams, headers, cacheOptions);

  /// POST
  Future<R> post(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
  }) {
    return _worker('POST', endpoint, body, queryParams, headers, cacheOptions);
  }

  Future<R> put(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
  }) {
    return _worker('PUT', endpoint, body, queryParams, headers, cacheOptions);
  }

  Future<R> delete(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    FetchHeaders headers = const {},
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
    FetchHeaders headers = const {},
    CacheOptions? cacheOptions,
  }) {
    return _worker('PATCH', endpoint, body, queryParams, headers, cacheOptions);
  }

  Future<FetchResponse> _runMethod(FetchPayload payload) async {
    final FetchPayload(:uri, :type, :body, :headers) = payload;
    final stopwatch = Stopwatch()..start();

    try {
      final response = await switch (type) {
        'GET' => http.get(uri, headers: headers).timeout(timeout),
        'HEAD' => http.head(uri, headers: headers).timeout(timeout),
        'POST' => http.post(uri, headers: headers, body: body).timeout(timeout),
        'PUT' => http.put(uri, headers: headers, body: body).timeout(timeout),
        'PATCH' =>
          http.patch(uri, headers: headers, body: body).timeout(timeout),
        'DELETE' =>
          http.delete(uri, headers: headers, body: body).timeout(timeout),
        _ => throw UnsupportedError('Unsupported type: $type')
      };

      stopwatch.stop();

      return FetchResponse.fromResponse(
        response,
        encoding: encoding,
        elapsed: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      rethrow;
    }
  }

  Future<R> _worker(
    String type,
    String path,
    Object? body,
    Map<String, dynamic>? queryParams,
    FetchHeaders headers,
    CacheOptions? cacheOptions,
  ) async {
    /// Create uri
    final Uri uri;

    if (path.startsWith('http')) {
      final parseUri = Uri.parse(path);
      uri = parseUri.replace(
        queryParameters: FetchHelpers.mapStringy({
          ...parseUri.queryParameters,
          ...?queryParams,
        }),
      );
    } else {
      uri = base.replace(
        path: (base.path + path).replaceAll(RegExp('//+'), '/'),
        queryParameters: FetchHelpers.mapStringy({
          ...base.queryParameters,
          ...?queryParams,
        }),
      );
    }

    final mergedHeaders = FetchHelpers.mergeHeaders(
      [await headerBuilder?.call() ?? {}, headers],
    );

    // if (!(await shouldRequest?.call(uri, mergedHeaders) ?? true)) {
    //   stopwatch.stop();
    //   log(cancelledResponse, stopwatch.elapsed, postBody: body);
    //   return transform?.call(cancelledResponse) ?? cancelledResponse as R;
    // }

    // ignore: no_leading_underscores_for_local_identifiers
    final _cacheOptions = cacheOptions ?? this.cacheOptions;
    final cached = isCached(uri, _cacheOptions);

    final FetchResponse response;
    final payload = FetchPayload(
      uri: uri,
      type: type,
      headers: mergedHeaders,
      body: body,
    );

    if (cached) {
      response = resolveCache(uri, _cacheOptions)!.response;
    }

    /// Override
    else if (override != null) {
      response = await override!(payload, _runMethod);
    }

    /// Request
    else {
      response = await _runMethod(payload);
      cache(response, uri, _cacheOptions);
    }

    /// Log
    log(response, postBody: body, isCached: cached);

    /// Complete
    final result = await transform?.call(response) ?? response as R;

    _onFetchController.add(result);

    return result;
  }
}

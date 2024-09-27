// ignore_for_file: constant_identifier_names

library fetch;

import 'dart:async';
import 'dart:convert';

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
    required this.method,
    this.headers,
    this.body,
  });

  final Uri uri;
  final String method;
  final Object? body;
  final FetchHeaders? headers;

  FetchPayload copyWith({
    Uri? uri,
    String? method,
    Object? body,
    FetchHeaders? headers,
  }) {
    return FetchPayload(
      uri: uri ?? this.uri,
      method: method ?? this.method,
      body: body ?? this.body,
      headers: headers ?? this.headers,
    );
  }

  @override
  String toString() {
    // ignore: lines_longer_than_80_chars
    return 'FetchPayload(method: $method, uri: $uri, headers: $headers, body: $body)';
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
        // ignore: lines_longer_than_80_chars
        'Fetch(...) must be Fetch<FetchResponse>(...) or transform method must be defined.',
      );
    }
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

  /// GET
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

  /// POST
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

  Future<FetchResponse> _runMethod(FetchPayload payload) async {
    final FetchPayload(:uri, :method, :body, :headers) = payload;

    final response = await switch (method) {
      'GET' => http.get(uri, headers: headers).timeout(timeout),
      'HEAD' => http.head(uri, headers: headers).timeout(timeout),
      'POST' => http.post(uri, headers: headers, body: body).timeout(timeout),
      'PUT' => http.put(uri, headers: headers, body: body).timeout(timeout),
      'PATCH' => http.patch(uri, headers: headers, body: body).timeout(timeout),
      'DELETE' =>
        http.delete(uri, headers: headers, body: body).timeout(timeout),
      _ => throw UnsupportedError('Unsupported method: $method')
    };

    return FetchResponse(
      response,
      encoding: encoding,
      postBody: payload.body,
    );
  }

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
    final stopwatch = Stopwatch()..start();

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

    // ignore: no_leading_underscores_for_local_identifiers
    final _cacheOptions = cacheOptions ?? this.cacheOptions;
    final cached = isCached(uri, _cacheOptions);

    late FetchResponse response;

    final payload = FetchPayload(
      uri: uri,
      body: body,
      method: method,
      headers: mergedHeaders,
    );

    if (cached) {
      response = resolveCache(uri, _cacheOptions)!.response;
    }

    /// Override
    else {
      if (override != null) {
        response = await override!(payload, _runMethod);
      }

      /// Request
      else {
        response = await _runMethod(payload);
      }

      cache(response, uri, _cacheOptions);
    }

    stopwatch.stop();

    response = response.copyWith(elapsed: stopwatch.elapsed);

    /// Log
    log(
      response,
      isCached: cached,
      enableLogs: enableLogs ?? this.enableLogs,
    );

    final R result;

    if (transform != null) {
      result = await transform!(response);
    } else {
      result = response as R;
    }

    _onFetchController.add(result);

    return result;
  }
}

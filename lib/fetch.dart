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
      body: body ?? this.body,
      method: method ?? this.method,
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

    return FetchResponse.fromResponse(
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

    final resolvedCache = resolveCache(uri, cacheOptions ?? this.cacheOptions);
    var response = resolvedCache?.response;

    final payload = FetchPayload(
      uri: uri,
      body: body,
      method: method,
      headers: mergedHeaders,
    );

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
    response.elapsed = stopwatch.elapsed;

    /// Log
    log(
      response,
      isCached: resolvedCache != null,
      enableLogs: enableLogs ?? this.enableLogs,
    );

    final result = switch (transform == null) {
      false => await transform!(response),
      true => response as R,
    };

    _onFetchController.add(result);

    return result;
  }
}

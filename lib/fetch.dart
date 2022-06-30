library fetch;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

part 'fetch_response.dart';
part 'fetch_config.dart';
part 'fetch_logger.dart';

void _notifyListeners(FetchLog fetchResponse, FetchConfig config) {
  if (config._streamController.hasListener) {
    config._streamController.add(fetchResponse);
  }
}

typedef FetchParams<T> = Map<String, T>;
typedef Mapper<T> = T? Function(Object? response);

class FetchBase<T extends Object?, R extends FetchResponse<T>> {
  FetchBase(this.endpoint, {this.mapper, this.config});

  final String endpoint;
  final Mapper<T>? mapper;
  final FetchParams params = {};
  final FetchConfig? config;

  FetchConfig get currentConfig => config ?? _fetchConfig;

  Future<R> get({
    FetchParams params = const {},
    FetchParams<String> headers = const {},
  }) async {
    this.params.addAll(params);

    final buildedHeaders = await currentConfig.headerBuilder(headers);
    final uri = currentConfig.uriBuilder(endpoint, params);

    try {
      final httpResponse = await http.get(uri, headers: buildedHeaders);

      _notifyListeners(
        FetchLog.fromHttpResponse(httpResponse),
        currentConfig,
      );

      final fetchResponse = await currentConfig.responseHandler<R, T>(
        httpResponse,
        mapper ?? currentConfig.mapper,
        params,
      );

      return fetchResponse;
    }

    // Knowns
    on SocketException catch (e) {
      _notifyListeners(
        FetchLog.error(
          method: 'GET',
          requestHeaders: buildedHeaders,
          url: uri.toString(),
          error: e.message,
        ),
        currentConfig,
      );

      rethrow;
    }

    // Others
    catch (e) {
      _notifyListeners(
        FetchLog.error(
          method: 'GET',
          requestHeaders: buildedHeaders,
          url: uri.toString(),
          error: e,
        ),
        currentConfig,
      );
      rethrow;
    }
  }

  Future<R> post(
    Object? body, {
    FetchParams params = const {},
    FetchParams<String> headers = const {},
  }) async {
    this.params.addAll(params);

    final buildedHeaders = await currentConfig.headerBuilder(headers);
    final postBody = currentConfig.postBodyEncoder(buildedHeaders, body);
    final uri = currentConfig.uriBuilder(endpoint, params);

    try {
      final httpResponse = await http.post(
        uri,
        body: postBody,
        headers: buildedHeaders,
      );

      _notifyListeners(
        FetchLog.fromHttpResponse(httpResponse, body),
        currentConfig,
      );

      final fetchResponse = await currentConfig.responseHandler<R, T>(
        httpResponse,
        mapper ?? currentConfig.mapper,
        params,
        body,
      );

      return fetchResponse;
    }

    // Knowns
    on SocketException catch (e) {
      _notifyListeners(
        FetchLog.error(
          method: 'POST',
          requestHeaders: buildedHeaders,
          url: uri.toString(),
          error: e.message,
        ),
        currentConfig,
      );
      rethrow;
    }

    // Others
    catch (e) {
      _notifyListeners(
        FetchLog.error(
          method: 'POST',
          requestHeaders: buildedHeaders,
          url: uri.toString(),
          error: e,
        ),
        currentConfig,
      );
      rethrow;
    }
  }
}

class Fetch<T> extends FetchBase<T, FetchResponse<T>> {
  Fetch(super.endpoint, {super.config, super.mapper});

  static void setConfig(FetchConfig config) {
    _fetchConfig = config;
  }

  static Future<FetchResponse<T>> getURL<T>(
    String url, {
    FetchParams params = const {},
    FetchParams<String> headers = const {},
    FetchConfig? config,
  }) async {
    final currentConfig = config ?? _fetchConfig;
    final buildedHeaders = await currentConfig.headerBuilder(headers);
    final uri = currentConfig.uriBuilder(url, params, overrided: true);
    final httpResponse = await http.get(uri, headers: buildedHeaders);

    _notifyListeners(
      FetchLog.fromHttpResponse(httpResponse),
      currentConfig,
    );

    return currentConfig.responseHandler<FetchResponse<T>, T>(
      httpResponse,
      (response) => response as T,
      params,
    );
  }

  static Future<FetchResponse<T>> postURL<T>(
    String url,
    Object? body, {
    FetchParams params = const {},
    FetchParams<String> headers = const {},
    FetchConfig? config,
  }) async {
    final currentConfig = config ?? _fetchConfig;
    final buildedHeaders = await currentConfig.headerBuilder(headers);
    final postBody = currentConfig.postBodyEncoder(buildedHeaders, body);
    final uri = currentConfig.uriBuilder(url, params, overrided: true);

    final httpResponse = await http.post(
      uri,
      body: postBody,
      headers: buildedHeaders,
    );

    _notifyListeners(
      FetchLog.fromHttpResponse(httpResponse, postBody),
      currentConfig,
    );

    return currentConfig.responseHandler<FetchResponse<T>, T>(
      httpResponse,
      (response) => response as T,
      params,
      body,
    );
  }
}

library fetch;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

part 'fetch_response.dart';
part 'fetch_config.dart';
part 'fetch_logger.dart';

typedef FetchParams<T> = Map<String, T>;
typedef Mapper<T> = FutureOr<T> Function(Object? response);

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

    try {
      final httpResponse = await http.get(
        currentConfig.uriBuilder(endpoint, params),
        headers: await currentConfig.headerBuilder(headers),
      );

      _fetchLogger(httpResponse, currentConfig);

      final fetchResponse = await currentConfig.responseHandler<R, T>(
        httpResponse,
        mapper ?? currentConfig.mapper,
      );

      _notifyListeners(fetchResponse);

      return fetchResponse;
    }

    // Knowns
    on SocketException catch (e) {
      final response = FetchResponse<T>.error(e.message);
      _notifyListeners(response);
      return Future.error(response);
    }

    // Others
    catch (e) {
      _notifyListeners(FetchResponse<T>.error(e.toString()));
      rethrow;
    }
  }

  Future<R> post(
    FetchParams body, {
    FetchParams params = const {},
    FetchParams<String> headers = const {},
  }) async {
    this.params.addAll(params);

    try {
      final httpResponse = await http.post(
        currentConfig.uriBuilder(endpoint, params),
        body: body,
        headers: await currentConfig.headerBuilder(headers),
      );

      _fetchLogger(httpResponse, currentConfig, body);

      final fetchResponse = await currentConfig.responseHandler<R, T>(
        httpResponse,
        mapper ?? currentConfig.mapper,
        body,
      );

      _notifyListeners(fetchResponse);

      return fetchResponse;
    }

    // Knowns
    on SocketException catch (e) {
      final response = FetchResponse<T>.error(e.message);
      _notifyListeners(response);
      return Future.error(response);
    }

    // Others
    catch (e) {
      _notifyListeners(FetchResponse<T>.error(e.toString()));
      rethrow;
    }
  }

  void _notifyListeners(FetchResponse<T?> fetchResponse) {
    if (currentConfig._streamController.hasListener) {
      currentConfig._streamController.add(fetchResponse);
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

    final httpResponse = await http.get(
      currentConfig.uriBuilder(url, params, overrided: true),
      headers: await currentConfig.headerBuilder(headers),
    );

    _fetchLogger(httpResponse, currentConfig);

    return currentConfig.responseHandler<FetchResponse<T>, T>(
      httpResponse,
      (response) => response as T,
    );
  }

  static Future<FetchResponse<T>> postURL<T>(
    String url,
    FetchParams body, {
    FetchParams params = const {},
    FetchParams<String> headers = const {},
    FetchConfig? config,
  }) async {
    final currentConfig = config ?? _fetchConfig;

    final httpResponse = await http.post(
      currentConfig.uriBuilder(url, params),
      headers: await currentConfig.headerBuilder(headers),
      body: body,
    );

    _fetchLogger(httpResponse, currentConfig);

    return currentConfig.responseHandler<FetchResponse<T>, T>(
      httpResponse,
      (response) => response as T,
      body,
    );
  }
}

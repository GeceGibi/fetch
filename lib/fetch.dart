library fetch;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

part 'fetch_response.dart';
part 'fetch_config.dart';
part 'fetch_logger.dart';

var _config = FetchConfig();
var _utf8Decoder = const Utf8Decoder();

typedef FetchParams<T> = Map<String, T>;
typedef Mapper<T> = FutureOr<T> Function(dynamic response);

class Fetch<T extends Object?> {
  Fetch(
    this.endpoint, {
    this.mapper,
  });

  final FetchParams params = {};
  final String endpoint;
  final Mapper<T>? mapper;

  static void setConfig<C extends FetchConfig>(C config) {
    _config = config;
  }

  Future<FetchResponse<T>> get({
    FetchParams params = const {},
    FetchParams<String> headers = const {},
  }) async {
    this.params.addAll(params);

    final httpResponse = await http.get(
      _config.getRequestUri(endpoint, params),
      headers: _config.headerBuilder(headers),
    );

    final fetchResponse = await _config.responseHandler<T>(
      httpResponse,
      mapper ?? _config.mapper,
    );

    notifyListeners(fetchResponse, httpResponse);

    return fetchResponse;
  }

  Future<FetchResponse<T>> post(
    FetchParams body, [
    FetchParams params = const {},
    FetchParams<String> headers = const {},
  ]) async {
    this.params.addAll(params);

    final httpResponse = await http.post(
      _config.getRequestUri(endpoint, params),
      body: jsonEncode(body),
      headers: _config.headerBuilder(headers),
    );

    final fetchResponse = await _config.responseHandler<T>(
      httpResponse,
      mapper ?? _config.mapper,
      body,
    );

    notifyListeners(fetchResponse, httpResponse);

    return fetchResponse;
  }

  void notifyListeners(
    FetchResponse<T> fetchResponse,
    HttpResponse httpResponse,
  ) {
    if (_config._streamController.hasListener) {
      _config._streamController.add(fetchResponse);
    }

    if (!const bool.fromEnvironment('dart.vm.product') &&
        _config.loggerEnabled) {
      _logger(httpResponse);
    }
  }
}

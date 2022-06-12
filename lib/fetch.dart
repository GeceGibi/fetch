library fetch;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

part 'fetch_response.dart';
part 'fetch_config.dart';
part 'fetch_logger.dart';

var _utf8Decoder = const Utf8Decoder();

typedef FetchParams<T> = Map<String, T>;
typedef Mapper<T> = FutureOr<T> Function(dynamic response);

class Fetch<T extends Object?, R extends FetchResponse<T>> {
  Fetch(this.endpoint, {this.mapper});

  final String endpoint;
  final Mapper<T>? mapper;
  final FetchParams params = {};

  Future<R> get({
    FetchParams params = const {},
    FetchParams<String> headers = const {},
  }) async {
    this.params.addAll(params);

    try {
      final httpResponse = await http.get(
        _config.getRequestUri(endpoint, params),
        headers: _config.headerBuilder(headers),
      );

      final fetchResponse = await _config.responseHandler<R, T>(
        httpResponse,
        mapper ?? _config.mapper,
      );

      _notifyListeners(fetchResponse, httpResponse);
      return fetchResponse;
    } on SocketException catch (e) {
      final fetchResponse = DefaultFetchResponse<T>.error(e.message);
      _notifyListeners(fetchResponse);
      return fetchResponse as R;
    }
  }

  Future<R> post(
    FetchParams body, [
    FetchParams params = const {},
    FetchParams<String> headers = const {},
  ]) async {
    this.params.addAll(params);

    try {
      final httpResponse = await http.post(
        _config.getRequestUri(endpoint, params),
        body: jsonEncode(body),
        headers: _config.headerBuilder(headers),
      );

      final fetchResponse = await _config.responseHandler<R, T>(
        httpResponse,
        mapper ?? _config.mapper,
        body,
      );

      _notifyListeners(fetchResponse);

      return fetchResponse;
    } on SocketException catch (e) {
      final fetchResponse = DefaultFetchResponse<T>.error(e.message);
      _notifyListeners(fetchResponse);
      return fetchResponse as R;
    }
  }

  void _notifyListeners(
    FetchResponse<T> fetchResponse, [
    HttpResponse? httpResponse,
  ]) {
    if (_config._onFetchStreamController.hasListener) {
      _config._onFetchStreamController.add(fetchResponse);
    }

    if (_config.loggerEnabled &&
        httpResponse != null &&
        !const bool.fromEnvironment('dart.vm.product')) {
      _logger(httpResponse);
    }
  }
}

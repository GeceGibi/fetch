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
    this.overrideConfig,
  });

  final FetchParams params = {};
  final String endpoint;
  final Mapper<T>? mapper;
  final FetchConfig? overrideConfig;

  static setConfig<C extends FetchConfig>(C config) {
    _config = config;
  }

  Future<FetchResponse<T>> get({
    FetchParams params = const {},
    FetchParams<String> headers = const {},
  }) async {
    return _config.responseHandler(
      await http.get(
        _config.getRequestUri(endpoint, params),
        headers: _config.headerBuilder(headers),
      ),
      mapper ?? _config.mapper,
    );
  }

  Future<FetchResponse<T>> post(
    FetchParams body, [
    FetchParams params = const {},
    FetchParams<String> headers = const {},
  ]) async {
    return _config.responseHandler(
      await http.post(
        _config.getRequestUri(endpoint, params),
        body: jsonEncode(body),
        headers: _config.headerBuilder(headers),
      ),
      mapper ?? _config.mapper,
      body,
    );
  }
}

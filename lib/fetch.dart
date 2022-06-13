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

abstract class FetchBase<T extends Object?, R extends FetchResponseBase<T>> {
  FetchBase(this.endpoint, {required this.config, this.mapper});

  final String endpoint;
  final Mapper<T>? mapper;
  final FetchParams params = {};
  final FetchConfig config;

  Future<R> get({
    FetchParams params = const {},
    FetchParams<String> headers = const {},
  }) async {
    this.params.addAll(params);

    try {
      final httpResponse = await http.get(
        config.getRequestUri(endpoint, params),
        headers: config.headerBuilder(headers),
      );

      final fetchResponse = await config.responseHandler<R, T>(
        httpResponse,
        mapper ?? config.mapper,
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
        config.getRequestUri(endpoint, params),
        body: jsonEncode(body),
        headers: config.headerBuilder(headers),
      );

      final fetchResponse = await config.responseHandler<R, T>(
        httpResponse,
        mapper ?? config.mapper,
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
    FetchResponseBase<T?> fetchResponse, [
    HttpResponse? httpResponse,
  ]) {
    if (config._onFetchStreamController.hasListener) {
      config._onFetchStreamController.add(fetchResponse);
    }

    if (config.loggerEnabled &&
        httpResponse != null &&
        !const bool.fromEnvironment('dart.vm.product')) {
      _logger(httpResponse);
    }
  }
}

library fetch;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

part 'fetch_response.dart';
part 'fetch_config.dart';
part 'fetch_logger.dart';
part 'fetch_helper.dart';

/// Global config
FetchConfigBase _fetchConfig = UnimplementedFetchConfig();

/// Default empty config
class UnimplementedFetchConfig extends FetchConfigBase {
  @override
  String get base => throw UnimplementedError();
}

void _notifyListeners<C extends FetchConfigBase>(
    FetchLog fetchResponse, C config) {
  if (config._streamController.hasListener) {
    config._streamController.add(fetchResponse);
  }
}

typedef FetchParams<T> = Map<String, T>;
typedef Mapper<T, R extends Object?> = T? Function(R response);

/// `R`: main response class must be extends from FetchResponse
///
/// `T`: return value of mapper and FetchResponse main payload Type;
///
/// `M`: income value of mapper, valus pass as M to mapper
///
/// If response allways be json can be use as Map<String,dynamic>.
/// Added for shorhands(lamdas) writing `mapper: ResposeClass.new`
class FetchBase<T extends Object?, R extends FetchResponse<T>> {
  FetchBase(this.endpoint, {this.config});

  final String endpoint;
  final FetchParams params = {};
  final FetchConfigBase? config;

  /// Get global fetch config or overrided config
  /// Checking first overrided one and ofter global one.
  FetchConfigBase get currentConfig => config ?? _fetchConfig;

  Future<R> get({
    FetchParams params = const {},
    FetchParams<String> headers = const {},
  }) async {
    this.params.addAll(params);

    final buildedHeaders = currentConfig.headerBuilder(headers);
    final uri = FetchHelper.uriBuilder(currentConfig.base + endpoint, params);

    try {
      final httpResponse = await http.get(uri, headers: buildedHeaders);

      _notifyListeners(
        FetchLog.fromHttpResponse(httpResponse),
        currentConfig,
      );

      final fetchResponse = await currentConfig.responseHandler<R, T>(
        httpResponse,
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

    final buildedHeaders = currentConfig.headerBuilder(headers);
    final postBody = currentConfig.postBodyEncoder(buildedHeaders, body);
    final uri = FetchHelper.uriBuilder(currentConfig.base + endpoint, params);

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
  Fetch(super.endpoint, {super.config});

  static void setConfig<C extends FetchConfigBase>(C config) {
    _fetchConfig = config;
  }

  static Future<FetchResponse<T>> getURL<T>(
    String url, {
    FetchParams params = const {},
    FetchParams<String> headers = const {},
    FetchConfigBase? config,
  }) async {
    final currentConfig = config ?? _fetchConfig;
    final buildedHeaders = currentConfig.headerBuilder(headers);
    final uri = FetchHelper.uriBuilder(url, params, overrided: true);
    final httpResponse = await http.get(uri, headers: buildedHeaders);

    _notifyListeners(
      FetchLog.fromHttpResponse(httpResponse),
      currentConfig,
    );

    return currentConfig.responseHandler<FetchResponse<T>, T>(
      httpResponse,
      params,
    );
  }

  static Future<FetchResponse<T>> postURL<T>(
    String url,
    Object? body, {
    FetchParams params = const {},
    FetchParams<String> headers = const {},
    FetchConfigBase? config,
  }) async {
    final currentConfig = config ?? _fetchConfig;
    final buildedHeaders = currentConfig.headerBuilder(headers);
    final postBody = currentConfig.postBodyEncoder(buildedHeaders, body);
    final uri = FetchHelper.uriBuilder(url, params, overrided: true);

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
      params,
      body,
    );
  }
}

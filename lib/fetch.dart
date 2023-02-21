library fetch;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

part 'logger.dart';
part 'helpers.dart';
part 'response.dart';

class Fetch extends FetchLogger {
  Fetch({required String from}) : _base = from;

  ///
  final String _base;
  final Map<String, dynamic> baseHeaders = {};
  late final Stream<FetchLog> onFetch = _onFetchController.stream;

  Future<FetchResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
  }) async {
    final stopwatch = Stopwatch();

    /// Create uri
    final uri = Uri.parse(
      endpoint.startsWith('http') ? endpoint : _base + endpoint,
    );

    /// Make request
    try {
      stopwatch.start();

      final response = await http.get(
        uri.replace(queryParameters: queryParams),
        headers: {...baseHeaders, ...headers},
      );

      stopwatch.stop();

      _log(response, stopwatch.elapsed);
      return _responseHandler(response);
    } catch (e, trace) {
      _logError(e, trace);
      return _responseHandler(null, e);
    }
  }

  Future<FetchResponse<T>> post<T>(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
  }) async {
    final stopwatch = Stopwatch();

    /// Create uri
    final uri = Uri.parse(
      endpoint.startsWith('http') ? endpoint : _base + endpoint,
    );

    /// Make request
    try {
      stopwatch.start();

      final response = await http.post(
        uri.replace(queryParameters: queryParams),
        body: body,
        headers: {...baseHeaders, ...headers},
      );

      stopwatch.stop();

      _log(response, stopwatch.elapsed);
      return _responseHandler(response);
    } catch (e, trace) {
      _logError(e, trace);
      return _responseHandler(null, e);
    }
  }

  FetchResponse<T> _responseHandler<T>(
    HttpResponse? response, [
    Object? error,
  ]) {
    if (response == null) {
      return FetchResponse<T>.error('$error');
    }

    return FetchResponse<T>.success(
      data: FetchHelpers.handleResponseBody(response),
      isSuccess: response.statusCode >= 200 && response.statusCode <= 299,
      message: response.reasonPhrase ?? error.toString(),
    );
  }
}

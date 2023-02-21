library fetch;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

part 'logger.dart';
part 'helpers.dart';
part 'response.dart';

class Fetch extends FetchLogger {
  Fetch({
    required String from,
    this.headers = const {},
    this.handler,
  }) : _base = from;

  ///
  final String _base;
  final Map<String, dynamic> headers;
  final FetchResponse<T> Function<T>(HttpResponse? response, Object? error)?
      handler;

  /// Streams
  late final Stream<FetchLog> onFetch = _onFetchController.stream;
  late final Stream<FetchLog> onError = _onErrorController.stream;

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
        uri.replace(queryParameters: FetchHelpers.mapStringy(queryParams)),
        headers: FetchHelpers.mergeHeaders([this.headers, headers]),
      );

      stopwatch.stop();

      return _responseHandler(response, stopwatch: stopwatch);
    } catch (error, stackTrace) {
      return _responseHandler(null, error: error, stackTrace: stackTrace);
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

    /// Make
    try {
      stopwatch.start();

      final response = await http.post(
        uri.replace(queryParameters: FetchHelpers.mapStringy(queryParams)),
        body: body,
        headers: FetchHelpers.mergeHeaders([this.headers, headers]),
      );

      stopwatch.stop();

      return _responseHandler(response, stopwatch: stopwatch, postBody: body);
    } catch (error, stackTrace) {
      return _responseHandler(null, error: error, stackTrace: stackTrace);
    }
  }

  FetchResponse<T> _responseHandler<T>(
    HttpResponse? response, {
    StackTrace? stackTrace,
    Stopwatch? stopwatch,
    Object? error,
    Object? postBody,
  }) {
    if (response == null) {
      _logError(error, stackTrace);
    } else {
      _log(response, stopwatch!.elapsed, postBody: postBody);
    }

    if (response == null) {
      if (handler != null) {
        return handler!(null, error);
      } else {
        return FetchResponse<T>.error('$error');
      }
    }

    if (handler != null) {
      return handler!(response, error);
    }

    return FetchResponse<T>.success(
      data: FetchHelpers.handleResponseBody(response),
      isSuccess: response.statusCode >= 200 && response.statusCode <= 299,
      message: response.reasonPhrase ?? error.toString(),
    );
  }
}

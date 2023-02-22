library fetch;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

part 'logger.dart';
part 'helpers.dart';
part 'response.dart';

bool _shouldRequest(Uri uri, Map<String, String> headers) => true;

class Fetch extends FetchLogger {
  Fetch({
    required String from,
    this.headers = const {},
    this.handler,
    this.timeout = const Duration(seconds: 30),
    this.afterRequest,
    this.beforeRequest,
    this.shouldRequest = _shouldRequest,
  }) : _base = from;

  ///
  final String _base;
  final Duration timeout;
  final Map<String, dynamic> headers;
  final FetchResponse<T> Function<T>(HttpResponse? response, Object? error)?
      handler;

  /// Streams
  late final Stream<FetchLog> onFetchSuccess = _onFetchController.stream;
  late final Stream<FetchLog> onFetchError = _onErrorController.stream;

  /// Lifecycle
  final void Function(Uri uri)? beforeRequest;
  final void Function(HttpResponse? response, Object? error)? afterRequest;
  final FutureOr<bool> Function(Uri uri, Map<String, String> headers)
      shouldRequest;

  Future<FetchResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
  }) async {
    final completer = Completer<FetchResponse<T>>();
    final stopwatch = Stopwatch();

    /// Make request
    try {
      /// Create uri
      final uri = Uri.parse(
        endpoint.startsWith('http') ? endpoint : _base + endpoint,
      ).replace(queryParameters: FetchHelpers.mapStringy(queryParams));

      final mergedHeaders = FetchHelpers.mergeHeaders([this.headers, headers]);

      if (!(await shouldRequest(uri, mergedHeaders))) {
        throw 'Request aborted from "shouldRequest"';
      }

      beforeRequest?.call(uri);
      stopwatch.start();

      final response =
          await http.get(uri, headers: mergedHeaders).timeout(timeout);

      stopwatch.stop();

      completer.complete(
        _responseHandler(
          response,
          stopwatch: stopwatch,
        ),
      );

      afterRequest?.call(response, null);
    } catch (error, stackTrace) {
      completer.complete(
        _responseHandler(
          null,
          error: error,
          stackTrace: stackTrace,
        ),
      );

      afterRequest?.call(null, error);
    }

    return completer.future;
  }

  Future<FetchResponse<T>> post<T>(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    Map<String, String> headers = const {},
  }) async {
    final completer = Completer<FetchResponse<T>>();
    final stopwatch = Stopwatch();

    /// Make
    try {
      /// Create uri
      final uri = Uri.parse(
        endpoint.startsWith('http') ? endpoint : _base + endpoint,
      ).replace(queryParameters: FetchHelpers.mapStringy(queryParams));

      final mergedHeaders = FetchHelpers.mergeHeaders([this.headers, headers]);

      if (!(await shouldRequest(uri, mergedHeaders))) {
        throw 'Request aborted from "shouldRequest"';
      }

      beforeRequest?.call(uri);
      stopwatch.start();

      final response = await http
          .post(uri, body: body, headers: mergedHeaders)
          .timeout(timeout);

      stopwatch.stop();

      completer.complete(
        _responseHandler(
          response,
          stopwatch: stopwatch,
          postBody: body,
        ),
      );

      afterRequest?.call(response, null);
    } catch (error, stackTrace) {
      completer.complete(
        _responseHandler(
          null,
          error: error,
          stackTrace: stackTrace,
        ),
      );

      afterRequest?.call(null, error);
    }

    return completer.future;
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
      isSuccess: FetchHelpers.isSuccess(response.statusCode),
      message: response.reasonPhrase ?? error.toString(),
    );
  }
}

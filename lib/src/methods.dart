import 'dart:async';

import 'package:via/via.dart';

/// A mixin that provides shorthand methods for common HTTP operations.
mixin ViaMethods<R extends ViaResult> {
  /// Internal helper to reduce code duplication in the mixin.
  Future<ViaBaseResult> _request(
    ViaMethod method,
    String endpoint, {
    Object? body,
    Map<String, ViaFile>? files,
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
    Runner? runner,
    bool isStream = false,
  }) {
    return (this as Via<R>).worker(
      method,
      endpoint: endpoint,
      body: body,
      files: files,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      pipelines: pipelines,
      runner: runner,
      isStream: isStream,
    );
  }

  /// Performs a multipart request.
  ///
  /// This is the dedicated method for sending form-data and files.
  Future<R> multipart(
    String endpoint, {
    Map<String, dynamic>? fields,
    Map<String, ViaFile>? files,
    ViaMethod method = .post,
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async =>
      (await _request(
        method,
        endpoint,
        body: fields,
        files: files,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      )) as R;

  /// Performs a GET request.
  Future<R> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async =>
      (await _request(
        .get,
        endpoint,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      )) as R;

  /// Performs a HEAD request.
  Future<R> head(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async =>
      (await _request(
        .head,
        endpoint,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      )) as R;

  /// Performs a POST request.
  Future<R> post(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async =>
      (await _request(
        .post,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      )) as R;

  /// Performs a PUT request.
  Future<R> put(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async =>
      (await _request(
        .put,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      )) as R;

  /// Performs a DELETE request.
  Future<R> delete(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async =>
      (await _request(
        .delete,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      )) as R;

  /// Performs a PATCH request.
  Future<R> patch(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async =>
      (await _request(
        .patch,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      )) as R;

  /// Performs a request and returns the response as a stream of bytes.
  ///
  /// This automatically bypasses global runners (like Isolates) for real-time processing.
  Future<ViaResultStream> stream(
    String endpoint, {
    ViaMethod method = .get,
    Object? body,
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async {
    final result = await _request(
      method,
      endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      cancelToken: cancelToken,
      pipelines: pipelines,
      isStream: true,
    );
    return result as ViaResultStream;
  }
}

import 'dart:async';

import 'package:via/via.dart';

/// A mixin that provides shorthand methods for common HTTP operations.
mixin ViaMethods<R extends ViaResult> {
  /// Internal helper to reduce code duplication in the mixin.
  Future<T> _request<T extends ViaBaseResult>(
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
    return (this as Via<R>).worker<T>(
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
      _request<R>(
        method,
        endpoint,
        body: fields,
        files: files,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      );

  /// Performs a GET request.
  Future<R> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async =>
      _request<R>(
        .get,
        endpoint,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      );

  /// Performs a HEAD request.
  Future<R> head(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async =>
      _request<R>(
        .head,
        endpoint,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      );

  /// Performs a POST request.
  Future<R> post(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async =>
      _request<R>(
        .post,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      );

  /// Performs a PUT request.
  Future<R> put(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async =>
      _request<R>(
        .put,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      );

  /// Performs a DELETE request.
  Future<R> delete(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async =>
      _request<R>(
        .delete,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      );

  /// Performs a PATCH request.
  Future<R> patch(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) async =>
      _request<R>(
        .patch,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      );

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
  }) async =>
      _request<ViaResultStream>(
        method,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
        isStream: true,
      );
}

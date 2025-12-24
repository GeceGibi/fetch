import 'dart:async';

import 'package:via/via.dart';

/// A mixin that provides shorthand methods for common HTTP operations.
mixin ViaMethods<R extends ViaResult> {
  /// Internal helper to reduce code duplication in the mixin.
  ViaCall<R> _request(
    ViaMethod method,
    String endpoint, {
    Object? body,
    Map<String, ViaFile>? files,
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
    Runner? runner,
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
    );
  }

  /// Performs a multipart request.
  ///
  /// This is the dedicated method for sending form-data and files.
  ViaCall<R> multipart(
    String endpoint, {
    Map<String, dynamic>? fields,
    Map<String, ViaFile>? files,
    ViaMethod method = .post,
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) =>
      _request(
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
  ViaCall<R> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) =>
      _request(
        .get,
        endpoint,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      );

  /// Performs a HEAD request.
  ViaCall<R> head(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) =>
      _request(
        .head,
        endpoint,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      );

  /// Performs a POST request.
  ViaCall<R> post(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) =>
      _request(
        .post,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      );

  /// Performs a PUT request.
  ViaCall<R> put(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) =>
      _request(
        .put,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      );

  /// Performs a DELETE request.
  ViaCall<R> delete(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) =>
      _request(
        .delete,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      );

  /// Performs a PATCH request.
  ViaCall<R> patch(
    String endpoint,
    Object? body, {
    Map<String, dynamic>? queryParams,
    ViaHeaders headers = const {},
    CancelToken? cancelToken,
    List<ViaPipeline> pipelines = const [],
  }) =>
      _request(
        .patch,
        endpoint,
        body: body,
        queryParams: queryParams,
        headers: headers,
        cancelToken: cancelToken,
        pipelines: pipelines,
      );

  /// Creates a new WebSocket connection.
  ///
  /// Uses the [base] URI and combines it with [endpoint].
  /// [headers] and [queryParams] are applied to the connection request.
  /// [pipelines] - Optional socket-specific pipelines for processing.
  /// [autoReconnect] - Whether to automatically attempt reconnection on disconnection.
  /// [reconnectDelay] - Delay between reconnection attempts.
  Future<ViaSocket> socket(
    String endpoint, {
    Iterable<String>? protocols,
    ViaHeaders? headers,
    Map<String, dynamic>? queryParams,
    Duration? timeout,
    List<ViaSocketPipeline> pipelines = const [],
    bool autoReconnect = false,
    Duration reconnectDelay = const Duration(seconds: 5),
  }) async {
    final via = this as Via<R>;
    final Uri uri;

    if (endpoint.startsWith('ws')) {
      uri = Uri.parse(endpoint).replace(
        queryParameters: ViaHelpers.mapStringy({
          ...?queryParams,
        }),
      );
    } else {
      // Automatic conversion: http -> ws, https -> wss
      final wsScheme = via.base.isScheme('https') ? 'wss' : 'ws';
      uri = via.base.replace(
        scheme: wsScheme,
        path: (via.base.path + endpoint).replaceAll(RegExp('//+'), '/'),
        queryParameters: ViaHelpers.mapStringy({
          ...via.base.queryParameters,
          ...?queryParams,
        }),
      );
    }

    return ViaSocket.connect(
      uri,
      protocols: protocols,
      headers: headers,
      timeout: timeout ?? via.timeout,
      pipelines: pipelines,
      autoReconnect: autoReconnect,
      reconnectDelay: reconnectDelay,
    );
  }
}

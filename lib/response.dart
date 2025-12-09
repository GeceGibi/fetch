part of 'fetch.dart';

class FetchResponse {
  FetchResponse(
    this.response, {
    this.postBody,
    this.elapsed,
    FetchPayload? payload,
    FetchMethod? retryMethod,
  })  : _payload = payload,
        _retryMethod = retryMethod;

  final http.Response response;

  /// Whether the response indicates a successful HTTP status.
  ///
  /// Returns true if the status code is between 200 and 299 (inclusive).
  bool get isSuccess {
    return response.statusCode >= 200 && response.statusCode <= 299;
  }

  /// Request duration (time taken to complete the request)
  Duration? elapsed;

  /// The original request body (for logging purposes)
  final Object? postBody;

  /// Internal: Original request payload for retry
  final FetchPayload? _payload;

  /// Internal: Method to call for retry
  final FetchMethod? _retryMethod;

  /// Retries the request with optional payload modification.
  ///
  /// [onRetry] - Optional callback to modify the payload before retrying.
  ///             Receives the original payload and returns a modified payload.
  ///             If not provided, retries with the original payload.
  ///
  /// Returns a new FetchResponse with the retry result.
  /// Throws [UnsupportedError] if retry is not available (e.g., response from cache).
  ///
  /// Example:
  /// ```dart
  /// // Retry with original payload
  /// await response.retry();
  ///
  /// // Retry with modified payload
  /// await response.retry((payload) {
  ///   return payload.copyWith(
  ///     headers: {'Authorization': 'Bearer new-token'},
  ///   );
  /// });
  /// ```
  Future<FetchResponse> retry([
    FetchPayload Function(FetchPayload payload)? onRetry,
  ]) async {
    if (_retryMethod == null || _payload == null) {
      throw UnsupportedError(
        'Retry is not available for this response. '
        'This might be a cached response or the retry capability was not enabled.',
      );
    }

    final payload = onRetry?.call(_payload!) ?? _payload!;
    return _retryMethod!(payload);
  }

  /// Converts the JSON response to a strongly-typed Map.
  ///
  /// [K] - The type of map keys
  /// [V] - The type of map values
  ///
  /// Returns a Map<K, V> if the JSON body is a map, throws ArgumentError otherwise.
  ///
  /// Example:
  /// ```dart
  /// final Map<String, dynamic> data = await response.asMap<String, dynamic>();
  /// ```
  FutureOr<Map<K, V>> asMap<K, V>() async {
    final jsonBody = jsonDecode(response.body);

    if (jsonBody is! Map) {
      throw ArgumentError(
        '${jsonBody.runtimeType} is not subtype of Map<$K, $V>',
        'asMap<$K, $V>',
      );
    }

    return jsonBody.cast<K, V>();
  }

  /// Converts the JSON response to a strongly-typed List.
  ///
  /// [E] - The type of list elements
  ///
  /// Returns a List<E> if the JSON body is a list, throws ArgumentError otherwise.
  ///
  /// Example:
  /// ```dart
  /// final List<String> items = await response.asList<String>();
  /// ```
  FutureOr<List<E>> asList<E>() async {
    final jsonBody = jsonDecode(response.body);

    if (jsonBody is! List) {
      throw ArgumentError(
        '${jsonBody.runtimeType} is not subtype of List<$E>',
        'asList<$E>',
      );
    }

    return jsonBody.cast<E>();
  }
}


part of 'fetch.dart';

/// Wrapper of http.Response
typedef HttpResponse = http.Response;

class FetchResponse {
  const FetchResponse(
    this.data, {
    this.message,
    this.isOk = false,
    this.httpResponse,
    this.uri,
  });

  factory FetchResponse.fromHandler(
    HttpResponse? response,
    Object? error,
    Uri? uri,
  ) {
    if (error != null || response == null) {
      return FetchResponse(
        null,
        httpResponse: response,
        message: '$error',
        uri: uri,
      );
    }

    return FetchResponse(
      FetchHelpers.handleResponseBody(response),
      isOk: FetchHelpers.isOk(response),
      message: response.reasonPhrase ?? error.toString(),
      httpResponse: response,
      uri: uri,
    );
  }

  final Object? data;

  T cast<T>() {
    if (data is T) {
      return data as T;
    }

    throw _throw<T>();
  }

  Map<K, V> asMap<K, V>() {
    if (data is Map) {
      return (data! as Map).cast<K, V>();
    }

    throw _throw<Map<K, V>>();
  }

  List<E> asList<E>() {
    if (data is List) {
      return (data! as List).cast<E>();
    }

    throw _throw<List<E>>();
  }

  UnsupportedError _throw<T>() {
    return UnsupportedError('data<${data.runtimeType}> is not subtype of $T');
  }

  final Uri? uri;
  final bool isOk;
  final String? message;
  final HttpResponse? httpResponse;

  @override
  String toString() {
    return 'FetchResponse(data: $data, isOk: $isOk, message: $message, httpResponse: $httpResponse)';
  }
}

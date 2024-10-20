part of 'fetch.dart';

class FetchResponse extends http.Response {
  FetchResponse.fromResponse(
    http.Response response, {
    this.encoding = utf8,
    this.postBody,
    this.elapsed,
  }) : super.bytes(
          response.bodyBytes,
          response.statusCode,
          request: response.request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );

  bool get isSuccess {
    return statusCode >= 200 && statusCode <= 299;
  }

  Duration? elapsed;
  Encoding encoding;
  final Object? postBody;
}

mixin FetchJsonResponse {
  dynamic get jsonBody;

  FutureOr<Map<K, V>> asMap<K, V>() async {
    ArgumentError.checkNotNull(jsonBody);
    return (await jsonBody as Map).cast<K, V>();
  }

  FutureOr<List<E>> asList<E>() async {
    ArgumentError.checkNotNull(jsonBody);
    return (await jsonBody as List).cast<E>();
  }
}

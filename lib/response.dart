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

  Duration? elapsed;
  Encoding encoding;
  final Object? postBody;
}

mixin FetchJsonResponse {
  Encoding get encoding;
  http.Response get response;

  dynamic get data {
    return jsonDecode(encoding.decode(response.bodyBytes));
  }

  FutureOr<Map<K, V>> asMap<K, V>() {
    ArgumentError.checkNotNull(data);
    return (data as Map).cast<K, V>();
  }

  FutureOr<List<E>> asList<E>() {
    ArgumentError.checkNotNull(data);
    return (data as List).cast<E>();
  }
}

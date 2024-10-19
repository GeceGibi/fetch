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
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
          request: response.request,
        );

  Duration? elapsed;
  Encoding encoding;
  final Object? postBody;
}

mixin FetchJsonResponse {
  Encoding get encoding;
  http.Response get response;

  FutureOr<Map<K, V>> asMap<K, V>() {
    final data = jsonDecode(encoding.decode(response.bodyBytes));
    return (data as Map).cast<K, V>();
  }

  FutureOr<List<E>> asList<E>() {
    final data = jsonDecode(encoding.decode(response.bodyBytes));
    return (data as List).cast<E>();
  }
}

class Res extends FetchResponse {
  Res(
    super.response, {
    super.elapsed,
    super.encoding,
    super.postBody,
  }) : super.fromResponse();
}

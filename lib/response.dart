part of 'fetch.dart';

class FetchResponse extends http.Response with FetchJsonResponse {
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

  @override
  dynamic get jsonBody => jsonDecode(encoding.decode(bodyBytes))!;
}

mixin FetchJsonResponse {
  dynamic get jsonBody;

  FutureOr<Map<K, V>> asMap<K, V>() async {
    if (jsonBody is! Map) {
      throw ArgumentError(
        '${jsonBody.runtimeType} is not subtype of Map<$K, $V>',
        'asMap<$K, $V>',
      );
    }

    return (jsonBody as Map).cast<K, V>();
  }

  FutureOr<List<E>> asList<E>() async {
    if (jsonBody is! List) {
      throw ArgumentError(
        '${jsonBody.runtimeType} is not subtype of List<$E>',
        'asList<$E>',
      );
    }

    return (jsonBody as List).cast<E>();
  }
}

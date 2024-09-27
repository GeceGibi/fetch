part of 'fetch.dart';

class FetchResponse {
  FetchResponse(
    this.response, {
    this.encoding = utf8,
    this.postBody,
    this.elapsed,
  });

  final http.Response response;
  final Encoding encoding;
  final Duration? elapsed;
  final Object? postBody;

  FutureOr<Map<K, V>> asMap<K, V>() {
    final data = jsonDecode(encoding.decode(response.bodyBytes));
    return (data as Map).cast<K, V>();
  }

  FutureOr<List<E>> asList<E>() {
    final data = jsonDecode(encoding.decode(response.bodyBytes));
    return (data as List).cast<E>();
  }

  bool get isSuccess {
    return response.statusCode >= 200 && response.statusCode <= 299;
  }

  FetchResponse copyWith({
    http.Response? response,
    Duration? elapsed,
    Encoding? encoding,
    Object? postBody,
  }) {
    return FetchResponse(
      response ?? this.response,
      elapsed: elapsed ?? this.elapsed,
      encoding: encoding ?? this.encoding,
      postBody: postBody ?? this.postBody,
    );
  }
}

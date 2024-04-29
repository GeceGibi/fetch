part of 'fetch.dart';

/// Wrapper of http.Response

typedef FetchBaseRequest = http.BaseRequest;

class FetchResponseJson {
  FetchResponseJson(this.data);
  final Object? data;

  Map<K, V> asMap<K, V>() {
    ArgumentError.checkNotNull(data);
    return (data! as Map).cast<K, V>();
  }

  List<E> asList<E>() {
    ArgumentError.checkNotNull(data);
    return (data! as List).cast<E>();
  }

  static FutureOr<FetchResponseJson> fromBytes(
    List<int> bytes, {
    Encoding encoding = systemEncoding,
  }) async {
    return FetchResponseJson(jsonDecode(encoding.decode(bytes)));
  }
}

class FetchResponse extends http.Response {
  FetchResponse(
    super.body,
    super.statusCode, {
    super.reasonPhrase,
    super.headers,
    super.isRedirect,
    super.persistentConnection,
    super.request,
  });

  FetchResponse.bytes(
    super.bodyBytes,
    super.statusCode, {
    super.reasonPhrase,
    super.headers,
    super.isRedirect,
    super.persistentConnection,
    super.request,
  }) : super.bytes();

  FetchResponse.fromResponse(http.Response response)
      : super.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
          request: response.request,
        );

  bool get isSuccess => statusCode >= 200 && statusCode <= 299;

  FetchResponseJson? _json;
  FutureOr<FetchResponseJson> asJson() async {
    _json ??= await FetchResponseJson.fromBytes(bodyBytes);
    return _json!;
  }

  FutureOr<T> cast<T>() async {
    return switch (T) {
      const (Map) => (await asJson()).asMap<dynamic, dynamic>(),
      const (List) => (await asJson()).asList<dynamic>(),
      const (int) => int.parse(body),
      const (double) => double.parse(body),
      const (num) => num.parse(body),
      const (String) => body,
      _ => body,
    } as T;
  }

  String describe() {
    final message = <String, dynamic>{
      'body': body,
      'statusCode': statusCode,
      'reasonPhrase': reasonPhrase,
      'contentLength': contentLength,
    };

    final content = [
      for (final MapEntry(:key, :value) in message.entries) '$key: $value',
    ].join(', ');

    return 'FetchResponse($content)';
  }

  FetchResponse copyWith({
    String? body,
    int? statusCode,
    String? reasonPhrase,
    FetchHeaders? headers,
    bool? isRedirect,
    bool? persistentConnection,
    FetchBaseRequest? request,
  }) {
    return FetchResponse(
      body ?? this.body,
      statusCode ?? this.statusCode,
      reasonPhrase: reasonPhrase ?? super.reasonPhrase,
      headers: headers ?? this.headers,
      isRedirect: isRedirect ?? this.isRedirect,
      persistentConnection: persistentConnection ?? this.persistentConnection,
      request: request ?? this.request,
    );
  }
}

class FetchRequest extends http.BaseRequest {
  FetchRequest(super.method, super.url);
}

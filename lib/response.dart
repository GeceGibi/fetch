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

class FetchError {
  const FetchError(this.body, this.stackTrace);
  final Object body;
  final StackTrace stackTrace;

  @override
  String toString() {
    return 'FetchError($body, $stackTrace)';
  }
}

class FetchRequest extends http.BaseRequest {
  FetchRequest(super.method, super.url);
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
    this.encoding = systemEncoding,
    this.elapsed = Duration.zero,
    this.error,
  });

  FetchResponse.bytes(
    super.bodyBytes,
    super.statusCode, {
    super.reasonPhrase,
    super.headers,
    super.isRedirect,
    super.persistentConnection,
    super.request,
    this.encoding = systemEncoding,
    this.elapsed = Duration.zero,
  })  : error = null,
        super.bytes();

  FetchResponse.fromResponse(
    http.Response response, {
    this.encoding = systemEncoding,
    this.elapsed = Duration.zero,
  })  : error = null,
        super.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
          request: response.request,
        );

  FetchResponse.error(
    this.error,
    Uri uri,
    String method,
  )   : elapsed = Duration.zero,
        encoding = systemEncoding,
        super.bytes(
          [],
          1e3 ~/ 1,
          request: FetchRequest(method, uri),
        );

  bool get isSuccess => statusCode >= 200 && statusCode <= 299;

  final Encoding encoding;
  final Duration elapsed;

  //
  final FetchError? error;

  FetchResponseJson? _json;
  FutureOr<FetchResponseJson> asJson() async {
    _json ??= await FetchResponseJson.fromBytes(bodyBytes, encoding: encoding);
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
      'requested to ': request?.url,
      'status': '$statusCode | $reasonPhrase',
      'content': '${headers[HttpHeaders.contentTypeHeader]} | $contentLength',
      'elapsed': '${elapsed.inMilliseconds}ms',
    };

    final content = [
      for (final MapEntry(:key, :value) in message.entries) '$key: $value',
    ].join('\n');

    return content;
  }

  FetchResponse copyWith({
    String? body,
    int? statusCode,
    String? reasonPhrase,
    FetchHeaders? headers,
    bool? isRedirect,
    bool? persistentConnection,
    FetchBaseRequest? request,
    Duration? elapsed,
    FetchError? error,
  }) {
    return FetchResponse(
      body ?? this.body,
      statusCode ?? this.statusCode,
      reasonPhrase: reasonPhrase ?? super.reasonPhrase,
      headers: headers ?? this.headers,
      isRedirect: isRedirect ?? this.isRedirect,
      persistentConnection: persistentConnection ?? this.persistentConnection,
      request: request ?? this.request,
      elapsed: elapsed ?? this.elapsed,
      error: error ?? this.error,
    );
  }
}

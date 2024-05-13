part of 'fetch.dart';

/// Wrapper of http.Response

typedef FetchBaseRequest = http.BaseRequest;

class FetchJsonData {
  FetchJsonData(this.json);
  final dynamic json;

  Map<K, V> asMap<K, V>() {
    ArgumentError.checkNotNull(json);
    return (json as Map).cast<K, V>();
  }

  List<E> asList<E>() {
    ArgumentError.checkNotNull(json);
    return (json as List).cast<E>();
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
    this.error,
  }) : super.bytes();

  FetchResponse.fromResponse(
    http.Response response, {
    this.encoding = systemEncoding,
    this.elapsed = Duration.zero,
    this.error,
  }) : super.bytes(
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
  final FetchError? error;

  FetchJsonData? _json;
  FutureOr<FetchJsonData> asJson() {
    return _json ??= FetchJsonData(jsonDecode(encoding.decode(bodyBytes)));
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

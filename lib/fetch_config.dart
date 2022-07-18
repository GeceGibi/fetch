// ignore_for_file: no_leading_underscores_for_local_identifiers

part of fetch;

abstract class FetchConfigBase {
  /// Request base url
  /// It's mean this base will add every request on fetch and concat with ednpoint (base + endpoint)
  ///
  /// Ex.
  /// https://www.domain.com
  /// https://www.domain.com/api/v2
  String get base;

  /// Check response is success or not.
  ///
  /// Maybe will be need custom conditional check for response.
  bool isSuccess(HttpResponse response) {
    return response.statusCode >= 200 && response.statusCode <= 299;
  }

  /// Response Handler
  ///
  /// Creating `FetchResponse` or extended class in here.
  Future<R> responseHandler<R extends FetchResponse<T?>, T, M>(
    HttpResponse response,
    Mapper<T, M>? mapper,
    FetchParams params, [
    Object? body,
  ]) async {
    if (isSuccess(response)) {
      final responseBody = responseBodyBuilder(response);

      return FetchResponse<T>(
        mapper != null ? mapper(responseBody) : responseBody,
        isSuccess: true,
        message: null,
        params: params,
      ) as R;
    }

    return FetchResponse<T>.error(
      '${response.statusCode} - ${response.reasonPhrase}',
    ) as R;
  }

  /// Response body building
  ///
  /// Default behaivor is check `content-type` header and doing whats are need for this.
  /// It's not sensitive for `charset`, it's handled with `http` library.
  dynamic responseBodyBuilder(HttpResponse response) {
    final type = (response.headers['content-type'] ?? '');
    final splitted = type.split(';');
    final content = splitted.first;

    switch (content) {
      case 'application/json':
      case 'application/javascript':
        return jsonDecode(response.body);

      default:
        return response.body;
    }
  }

  /// Create post body
  ///
  /// Default behaivor is check `content-type` header and doing whats are need for this.
  /// If need to modify this please create new one and extend it with `FetchConfig` class
  dynamic postBodyEncoder(FetchParams<String> headers, Object? body) {
    final type = (headers['content-type'] ?? '').trim();
    final splitted = type.split(';');
    final content = splitted.first;

    switch (content) {
      case 'application/json':
      case 'application/javascript':
        return jsonEncode(body);

      default:
        return body;
    }
  }

  /// Http request headers building
  ///
  /// It's seperated function because some headers need dynamicly add or remove from headers.
  /// Ex. User auth status change. Check user status and add or remove here.
  FetchParams<String> headerBuilder(FetchParams<String> headers) {
    return {
      'content-type': "application/json",
      'x-http-version': FetchHelper.httpVersion,
      ...headers,
    };
  }

  final _streamController = StreamController<FetchLog>();

  /// Stream for every fetch action.
  ///
  /// Included `Fetch.getURL` and `Fetch.postURL` both
  Stream<FetchLog> get onFetch => _streamController.stream;
}

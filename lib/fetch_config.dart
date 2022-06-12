part of fetch;

class FetchConfig {
  final baseUri = Uri();
  final loggerEnabled = true;
  final dynamicQueryPattern = RegExp(r'{\s*(\w+?)\s*}');

  String? messageBuilder(HttpResponse response) {
    if (!isOk(response)) {
      return 'Bir sorun oluştu..';
    }

    return null;
  }

  FutureOr<T> mapper<T>(dynamic response) => response;

  bool isOk(HttpResponse response) {
    return response.statusCode >= 200 && response.statusCode <= 299;
  }

  Future<FetchResponse<T>> responseHandler<T>(
    HttpResponse response,
    Mapper<T> mapper, [
    FetchParams? body,
  ]) async {
    final message = messageBuilder(response);
    var responseShink = DefaultFetchResponse<T>.error(message);
    T payload;

    if (isOk(response)) {
      if (response.headers.containsKey('content-type') &&
          response.headers['content-type']!.contains('application/json')) {
        payload = await mapper(
          jsonDecode(_utf8Decoder.convert(response.bodyBytes)),
        );
      } else {
        payload = await mapper(response.body);
      }

      responseShink = DefaultFetchResponse<T>(
        payload,
        isSuccess: true,
        message: message,
      );
    }

    return responseShink;
  }

  Uri getRequestUri(String endpoint, FetchParams params) {
    final args = Map.of(params);
    final dropFromQuery = [];

    final dressed = endpoint.replaceAllMapped(
      dynamicQueryPattern,
      (match) {
        final key = match.group(1);

        if (args.containsKey(key)) {
          dropFromQuery.add(key);
          return '${args[key]}';
        }

        return '';
      },
    );

    args.removeWhere(
      (key, value) => dropFromQuery.contains(key) || value == null,
    );

    final query = args.isEmpty
        ? null
        : args.map((key, value) => MapEntry(key, value.toString()));

    return Uri.https(baseUri.host, baseUri.path + dressed, query);
  }

  String get httpVersion {
    var version = Platform.version;
    final index = version.indexOf('.', version.indexOf('.') + 1);
    version = version.substring(0, index);
    return 'Dart/$version (dart:io)';
  }

  FetchParams<String> headerBuilder(FetchParams<String> headers) {
    return {
      'content-type': "application/json",
      'http-version': httpVersion,
      ...headers,
    };
  }

  final _streamController = StreamController<FetchResponse>();
  Stream<FetchResponse> get onFetch => _streamController.stream;
}

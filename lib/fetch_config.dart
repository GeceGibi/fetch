part of fetch;

class FetchConfig {
  bool loggerEnabled = true;

  Uri get baseUri => Uri();

  RegExp dynamicQueryPattern = RegExp(r'{\s*(\w+?)\s*}');

  FutureOr<T> mapper<T>(dynamic response) => response;

  bool isOk(http.Response response) {
    return response.statusCode >= 200 && response.statusCode <= 299;
  }

  Future<FetchResponse<T>> responseHandler<T>(
    http.Response response,
    Mapper<T> mapper, [
    FetchParams? body,
  ]) async {
    var responseShink = FetchResponse<T>.error();

    if (!const bool.fromEnvironment('dart.vm.product') && loggerEnabled) {
      _logger(response, body);
    }

    if (isOk(response)) {
      if (response.headers.containsKey('content-type') &&
          response.headers['content-type']!.contains('json')) {
        final json = jsonDecode(_utf8Decoder.convert(response.bodyBytes));
        responseShink = FetchResponse.fromJson<T>(mapper(json));
      } else {
        responseShink = FetchResponse(
          response.body as T,
          message: null,
          isSuccess: true,
        );
      }
    }

    _streamController.add(responseShink);

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

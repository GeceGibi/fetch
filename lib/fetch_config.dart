part of fetch;

const _utf8Decoder = Utf8Decoder();
var _fetchConfig = FetchConfig();

class FetchConfig {
  final Uri base = Uri();
  final bool isLoggerEnabled = true;
  final RegExp dynamicQueryPattern = RegExp(r'{\s*(\w+?)\s*}');

  FutureOr<T> mapper<T>(Object? response) => response as T;

  FutureOr<bool> isSuccess(HttpResponse response) {
    return response.statusCode >= 200 && response.statusCode <= 299;
  }

  Future<R> responseHandler<R extends FetchResponse<T?>, T>(
    HttpResponse response,
    Mapper<T> mapper, [
    FetchParams? body,
  ]) async {
    var responseShink = FetchResponse<T>.error(
      '${response.statusCode} - ${response.reasonPhrase}',
    );

    if (await isSuccess(response)) {
      T payload;

      if (response.headers.containsKey('content-type') &&
          response.headers['content-type']!.contains('application/json')) {
        payload = await mapper(
          jsonDecode(_utf8Decoder.convert(response.bodyBytes)),
        );
      } else {
        payload = await mapper(response.body);
      }

      responseShink = FetchResponse<T>(
        payload,
        isSuccess: true,
        message: null,
      );
    }

    return responseShink as R;
  }

  Uri uriBuilder(String endpoint, FetchParams params) {
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

    return Uri.https(base.host, base.path + dressed, query);
  }

  String get httpVersion {
    var version = Platform.version;
    final index = version.indexOf('.', version.indexOf('.') + 1);
    version = version.substring(0, index);
    return 'Dart/$version (dart:io)';
  }

  FutureOr<FetchParams<String>> headerBuilder(
    FetchParams<String> headers,
  ) {
    return {
      'content-type': "application/json",
      'x-http-version': httpVersion,
      ...headers,
    };
  }

  final _streamController = StreamController<FetchResponse>();
  Stream<FetchResponse> get onFetch => _streamController.stream;
}

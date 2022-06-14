// ignore_for_file: no_leading_underscores_for_local_identifiers

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

  Uri uriBuilder(
    String endpoint,
    FetchParams params, {
    bool overrided = false,
  }) {
    final template = _templateParser(endpoint, params);
    final arguments = {
      ...template.replacedQuery,
      for (final entry in params.entries)
        if (!template.foundedKeys.contains(entry.key))
          entry.key: '${entry.value}',
    };

    final query = arguments.isEmpty
        ? null
        : arguments.entries.map((e) => '${e.key}=${e.value}').join('&');

    if (overrided) {
      return Uri.parse(template.replaced).replace(query: query);
    }

    return base.replace(path: base.path + template.replaced, query: query);
  }

  TemplateParserResult _templateParser(String template, FetchParams params) {
    final founded = <String>[];

    var replaced = template.replaceAllMapped(
      dynamicQueryPattern,
      (match) {
        final key = match.group(1);

        if (params.containsKey(key)) {
          founded.add(key!);
          return '${params[key]}';
        }

        return '';
      },
    );

    final hasQuery = replaced.contains('?');
    final query = <String, String>{};

    if (hasQuery) {
      final splitAtQuery = replaced.split('?');

      for (var entry in splitAtQuery.last.split('&')) {
        final value = entry.split('=');
        query[value.first] = value.last;
      }

      replaced = splitAtQuery.first;
    }

    return TemplateParserResult(
      replaced: replaced,
      replacedQuery: query,
      foundedKeys: founded,
    );
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

class TemplateParserResult {
  const TemplateParserResult({
    required this.replaced,
    required this.foundedKeys,
    required this.replacedQuery,
  });

  final String replaced;
  final Map<String, String> replacedQuery;
  final List<String> foundedKeys;
}

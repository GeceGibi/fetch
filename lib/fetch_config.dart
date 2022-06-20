// ignore_for_file: no_leading_underscores_for_local_identifiers

part of fetch;

const _utf8Decoder = Utf8Decoder();
var _fetchConfig = FetchConfig();

class FetchConfig {
  final Uri base = Uri();
  final RegExp dynamicQueryPattern = RegExp(r'{\s*(\w+?)\s*}');

  FutureOr<T> mapper<T>(Object? response) => response as T;

  FutureOr<bool> isSuccess(HttpResponse response) {
    return response.statusCode >= 200 && response.statusCode <= 299;
  }

  Future<R> responseHandler<R extends FetchResponse<T?>, T>(
    HttpResponse response,
    Mapper<T> mapper,
    FetchParams params, [
    FetchParams? body,
  ]) async {
    if (await isSuccess(response)) {
      return FetchResponse<T>(
        await mapper(payloadBuilder(response)),
        isSuccess: true,
        message: null,
        params: params,
      ) as R;
    }

    return FetchResponse<T>.error(
      '${response.statusCode} - ${response.reasonPhrase}',
    ) as R;
  }

  dynamic payloadBuilder(HttpResponse response) {
    final type = (response.headers['content-type'] ?? '');
    final splitted = type.split(';');
    final content = splitted.first;
    final charset = splitted.last.split('=').last.toLowerCase();

    switch (content) {
      case 'application/json':
      case 'application/javascript':
        if (charset == 'utf-8') {
          return jsonDecode(_utf8Decoder.convert(response.bodyBytes));
        } else {
          return jsonDecode(response.body);
        }

      default:
        return response.body;
    }
  }

  dynamic bodyBuilder(FetchParams<String> headers, FetchParams body) {
    final type = (headers['content-type'] ?? '');
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

  final _streamController = StreamController<FetchLog>();
  Stream<FetchLog> get onFetch => _streamController.stream;
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

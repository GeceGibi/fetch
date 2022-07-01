part of fetch;

class FetchHelper {
  static const ut8 = Utf8Codec();
  static final dynamicQueryPattern = RegExp(r'{\s*(\w+?)\s*}');

  static String get httpVersion {
    var version = Platform.version;
    final index = version.indexOf('.', version.indexOf('.') + 1);
    version = version.substring(0, index);
    return 'Dart/$version (dart:io)';
  }

  static Uri uriBuilder(
    String url,
    FetchParams params, {
    bool overrided = false,
  }) {
    final template = templateParser(url, params);
    final arguments = {
      ...template.replacedQuery,
      for (final entry in params.entries)
        if (!template.foundedKeys.contains(entry.key))
          entry.key: '${entry.value}',
    };

    final query = arguments.isEmpty
        ? null
        : arguments.entries.map((e) => '${e.key}=${e.value}').join('&');

    return Uri.parse(template.replaced).replace(query: query);
  }

  static TemplateParserResult templateParser(
    String template,
    FetchParams params,
  ) {
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

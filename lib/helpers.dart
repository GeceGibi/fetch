part of 'fetch.dart';

class FetchHelpers {
  static dynamic handleResponseBody(
    HttpResponse response, {
    Encoding encoding = utf8,
  }) {
    final contentType = response.headers['content-type'] ?? '';
    final jsonDecodeTypes = ['application/json', 'application/javascript'];

    for (final type in jsonDecodeTypes) {
      if (contentType.contains(type)) {
        return jsonDecode(encoding.decode(response.bodyBytes));
      }
    }

    return response.body;
  }

  static Map<String, String> mergeHeaders(List<Map<String, String>> headers) {
    final output = <String, String>{};

    for (final head in headers) {
      output.addAll(mapStringy(head) ?? {});
    }

    return output;
  }

  static Map<String, String>? mapStringy(Map<Object?, Object?>? map) {
    if (map == null || map.isEmpty) {
      return null;
    }

    return map.map<String, String>(
      (key, value) => MapEntry('$key', '$value'),
    );
  }

  static bool isOk(HttpResponse response) {
    return response.statusCode >= 200 && response.statusCode <= 299;
  }
}

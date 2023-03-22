part of fetch;

abstract class FetchHelpers {
  static T handleResponseBody<T>(HttpResponse response) {
    final contentType = (response.headers['content-type'] ?? '');
    final jsonDecodeTypes = ['application/json', 'application/javascript'];

    for (final type in jsonDecodeTypes) {
      if (contentType.contains(type)) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    }

    return response.body as T;
  }

  static Map<String, String> mergeHeaders(List<Map> headers) {
    var output = <String, String>{};

    for (final head in headers) {
      output.addAll(
        head.map<String, String>(
          (key, value) => MapEntry('$key', '$value'),
        ),
      );
    }

    return output;
  }

  static Map<String, String>? mapStringy(Map? map) {
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

part of 'fetch.dart';

class FetchHelpers {
  static FetchHeaders mergeHeaders(List<Map<Object?, Object?>> headers) {
    final output = <String, String>{};

    for (final head in headers) {
      output.addAll(mapStringy(head) ?? {});
    }

    return output;
  }

  static FetchHeaders? mapStringy(Map<Object?, Object?>? map) {
    if (map == null || map.isEmpty) {
      return null;
    }

    return map.map<String, String>(
      (key, value) => MapEntry('$key', '$value'),
    );
  }
}

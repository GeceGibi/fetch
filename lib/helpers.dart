part of 'fetch.dart';

/// Utility class providing helper methods for HTTP operations.
///
/// This class contains static methods for common HTTP-related operations
/// such as header merging and type conversion.
class FetchHelpers {
  /// Merges multiple header maps into a single map.
  ///
  /// This method combines multiple header maps, with later maps taking
  /// precedence over earlier ones in case of conflicts.
  ///
  /// [headers] - List of header maps to merge
  ///
  /// Returns a single merged header map.
  ///
  /// Example:
  /// ```dart
  /// final merged = FetchHelpers.mergeHeaders([
  ///   {'content-type': 'application/json'},
  ///   {'authorization': 'Bearer token'},
  /// ]);
  /// ```
  static FetchHeaders mergeHeaders(List<Map<Object?, Object?>> headers) {
    final output = <String, String>{};

    for (final head in headers) {
      output.addAll(mapStringy(head) ?? {});
    }

    return output;
  }

  /// Converts a map with any key/value types to a string map.
  ///
  /// This method safely converts map keys and values to strings.
  /// Returns null if the input is null or empty to prevent adding
  /// unnecessary query separators to URLs.
  ///
  /// [map] - The map to convert
  ///
  /// Example:
  /// ```dart
  /// final stringMap = FetchHelpers.mapStringy({
  ///   'key1': 'value1',
  ///   'key2': 123,
  ///   'key3': true,
  /// });
  /// // Result: {'key1': 'value1', 'key2': '123', 'key3': 'true'}
  /// ```
  static Map<String, String>? mapStringy(Map<Object?, Object?>? map) {
    if (map == null || map.isEmpty) {
      return null;
    }

    return map.map<String, String>(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }
}

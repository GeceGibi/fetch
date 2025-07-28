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
  /// This method safely converts map keys and values to strings,
  /// handling null values and empty maps appropriately.
  ///
  /// [map] - The map to convert
  ///
  /// Returns a Map<String, String> or null if the input is null or empty.
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
  static FetchHeaders? mapStringy(Map<Object?, Object?>? map) {
    if (map == null || map.isEmpty) {
      return null;
    }

    return map.map<String, String>(
      (key, value) => MapEntry('$key', '$value'),
    );
  }
}

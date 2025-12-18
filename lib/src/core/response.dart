import 'dart:async';
import 'dart:convert';

import 'package:fetch/src/core/payload.dart';
import 'package:http/http.dart' as http;

class FetchResponse {
  FetchResponse(
    this.response, {
    required this.payload,
    this.elapsed,
  });

  final http.Response response;

  /// Original request payload
  final FetchPayload payload;

  /// Whether the response indicates a successful HTTP status.
  ///
  /// Returns true if the status code is between 200 and 299 (inclusive).
  bool get isSuccess {
    return response.statusCode >= 200 && response.statusCode <= 299;
  }

  /// Request duration (time taken to complete the request)
  Duration? elapsed;

  /// Converts the JSON response to a strongly-typed Map.
  ///
  /// [K] - The type of map keys
  /// [V] - The type of map values
  ///
  /// Returns a Map<K, V> if the JSON body is a map, throws ArgumentError otherwise.
  ///
  /// Example:
  /// ```dart
  /// final Map<String, dynamic> data = await response.asMap<String, dynamic>();
  /// ```
  FutureOr<Map<K, V>> asMap<K, V>() async {
    final jsonBody = jsonDecode(response.body);

    if (jsonBody is! Map) {
      throw ArgumentError(
        '${jsonBody.runtimeType} is not subtype of Map<$K, $V>',
        'asMap<$K, $V>',
      );
    }

    return jsonBody.cast<K, V>();
  }

  /// Converts the JSON response to a strongly-typed List.
  ///
  /// [E] - The type of list elements
  ///
  /// Returns a List<E> if the JSON body is a list, throws ArgumentError otherwise.
  ///
  /// Example:
  /// ```dart
  /// final List<String> items = await response.asList<String>();
  /// ```
  FutureOr<List<E>> asList<E>() async {
    final jsonBody = jsonDecode(response.body);

    if (jsonBody is! List) {
      throw ArgumentError(
        '${jsonBody.runtimeType} is not subtype of List<$E>',
        'asList<$E>',
      );
    }

    return jsonBody.cast<E>();
  }

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln('${payload.method} ${payload.uri}')
      ..writeln('Status: ${response.statusCode} ${response.reasonPhrase}');

    if (elapsed != null) {
      buffer.writeln('Elapsed: ${elapsed!.inMilliseconds}ms');
    }

    if (response.headers.isNotEmpty) {
      buffer.writeln('Headers: ${response.headers}');
    }

    if (response.body.isNotEmpty) {
      buffer.writeln('Body: ${response.body}');
    }

    return buffer.toString().trimRight();
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': response.statusCode,
      'reasonPhrase': response.reasonPhrase,
      if (elapsed != null) 'elapsedMs': elapsed!.inMilliseconds,
      if (response.headers.isNotEmpty) 'headers': response.headers,
      if (response.body.isNotEmpty) 'body': response.body,
      'payload': payload.toJson(),
    };
  }
}

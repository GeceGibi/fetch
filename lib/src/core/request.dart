import 'dart:convert';

import 'package:via/src/core/helpers.dart';
import 'package:via/src/features/cancel.dart';

/// Represents the payload for an HTTP request.
///
/// This class encapsulates all the necessary information for making an HTTP request
/// including the URI, method, headers, and body.
class ViaRequest {
  /// Creates a new ViaRequest instance.
  ///
  /// [uri] - The target URI for the request
  /// [method] - The HTTP method (GET, POST, PUT, DELETE, etc.)
  /// [headers] - Optional HTTP headers
  /// [body] - Optional request body
  /// [cancelToken] - Optional token for cancelling the request
  ViaRequest({
    required this.uri,
    required this.method,
    this.headers,
    this.body,
    this.cancelToken,
  });

  /// The target URI for the request
  final Uri uri;

  /// The HTTP method (GET, POST, PUT, DELETE, etc.)
  final String method;

  /// Optional request body
  final Object? body;

  /// Optional HTTP headers
  final ViaHeaders? headers;

  /// Optional cancel token
  final CancelToken? cancelToken;

  /// Creates a copy of this ViaRequest with the given fields replaced by new values.
  ///
  /// Returns a new ViaRequest instance with updated values.
  ViaRequest copyWith({
    Uri? uri,
    String? method,
    Object? body,
    ViaHeaders? headers,
    CancelToken? cancelToken,
  }) {
    return ViaRequest(
      uri: uri ?? this.uri,
      body: body ?? this.body,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      cancelToken: cancelToken ?? this.cancelToken,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer()..writeln('$method $uri');

    if (headers?.isNotEmpty ?? false) {
      buffer.writeln('Headers: $headers');
    }

    if (body != null) {
      buffer.writeln('Body: $body');
    }

    return buffer.toString().trimRight();
  }

  Map<String, dynamic> toJson() {
    return {
      'uri': uri.toString(),
      'method': method,
      'headers': headers,
      'body': ?body,
    };
  }

  /// Generates a cURL command representation of the request.
  String toCurl() {
    final buffer = StringBuffer('curl -X $method');

    headers?.forEach((key, value) {
      final escapedValue = value.replaceAll('"', r'\"');
      buffer.write(' -H "$key: $escapedValue"');
    });

    if (body != null) {
      String data;
      if (body is String) {
        data = body! as String;
      } else if (body is Map || body is List) {
        data = jsonEncode(body);
      } else {
        data = body.toString();
      }

      final escapedBody = data.replaceAll("'", r"'\''");
      buffer.write(" -d '$escapedBody'");
    }

    buffer.write(' "$uri"');
    return buffer.toString();
  }
}

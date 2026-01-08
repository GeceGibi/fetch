import 'dart:convert';

import 'package:via/src/core/helpers.dart';
import 'package:via/src/features/cancel.dart';

enum ViaMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  patch('PATCH'),
  head('HEAD'),
  options('OPTIONS')
  ;

  const ViaMethod(this.value);
  final String value;
}

/// Represents a file for multipart requests.
class ViaFile {
  const ViaFile.fromBytes(this.bytes, {required this.filename}) : value = null;
  const ViaFile.fromString(this.value, {required this.filename}) : bytes = null;

  final List<int>? bytes;
  final String? value;
  final String filename;
}

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
  /// [files] - Optional files for multipart requests
  /// [cancelToken] - Optional token for cancelling the request
  ViaRequest({
    required this.uri,
    required this.method,
    this.headers,
    this.body,
    this.files,
    this.cancelToken,
    this.isStream = false,
  });

  /// The target URI for the request
  final Uri uri;

  /// The HTTP method (GET, POST, PUT, DELETE, etc.)
  final ViaMethod method;

  /// Optional request body
  final Object? body;

  /// Optional files for multipart requests
  final Map<String, ViaFile>? files;

  /// Optional HTTP headers
  final ViaHeaders? headers;

  /// Optional cancel token
  final CancelToken? cancelToken;

  /// Whether this request should be handled as a stream.
  /// If true, the executor will bypass global runners (like Isolates)
  /// to allow real-time stream processing.
  final bool isStream;

  /// Creates a copy of this ViaRequest with the given fields replaced by new values.
  ///
  /// Returns a new ViaRequest instance with updated values.
  ViaRequest copyWith({
    Uri? uri,
    ViaMethod? method,
    Object? body,
    Map<String, ViaFile>? files,
    ViaHeaders? headers,
    CancelToken? cancelToken,
    bool? isStream,
  }) {
    return ViaRequest(
      uri: uri ?? this.uri,
      body: body ?? this.body,
      files: files ?? this.files,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      cancelToken: cancelToken ?? this.cancelToken,
      isStream: isStream ?? this.isStream,
    );
  }

  /// Returns a version of this request that is safe to send through Isolates.
  ViaRequest toSafeVersion() {
    return copyWith(body: body is Stream ? 'Stream<List<int>>' : body);
  }

  @override
  String toString() {
    final buffer = StringBuffer()..writeln('${method.value} $uri');

    if (headers?.isNotEmpty ?? false) {
      buffer.writeln('Headers: $headers');
    }

    if (body != null) {
      buffer.writeln('Body: $body');
    }

    if (files != null) {
      buffer.writeln('Files: ${files!.keys.join(', ')}');
    }

    return buffer.toString().trimRight();
  }

  Map<String, dynamic> toJson() {
    return {
      'uri': uri.toString(),
      'method': method.value,
      'headers': headers,
      'body': body is Stream ? 'Stream<List<int>>' : body,
      'files': ?files?.keys.toList(),
    };
  }

  /// Generates a cURL command representation of the request.
  String toCurl() {
    final buffer = StringBuffer('curl -X ${method.value}');

    headers?.forEach((key, value) {
      final header = '$key: $value';
      final escapedHeader = header.replaceAll("'", r"'\''");
      buffer.write(" -H '$escapedHeader'");
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

    final escapedUri = uri.toString().replaceAll("'", r"'\''");
    buffer.write(" '$escapedUri'");
    return buffer.toString();
  }
}

import 'package:fetch/src/core/helpers.dart';
import 'package:fetch/src/features/cancel.dart';

/// Represents the payload for an HTTP request.
///
/// This class encapsulates all the necessary information for making an HTTP request
/// including the URI, method, headers, and body.
class FetchPayload {
  /// Creates a new FetchPayload instance.
  ///
  /// [uri] - The target URI for the request
  /// [method] - The HTTP method (GET, POST, PUT, DELETE, etc.)
  /// [headers] - Optional HTTP headers
  /// [body] - Optional request body
  /// [cancelToken] - Optional token for cancelling the request
  FetchPayload({
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
  final FetchHeaders? headers;

  /// Optional cancel token
  final CancelToken? cancelToken;

  /// Creates a copy of this FetchPayload with the given fields replaced by new values.
  ///
  /// Returns a new FetchPayload instance with updated values.
  FetchPayload copyWith({
    Uri? uri,
    String? method,
    Object? body,
    FetchHeaders? headers,
    CancelToken? cancelToken,
  }) {
    return FetchPayload(
      uri: uri ?? this.uri,
      body: body ?? this.body,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      cancelToken: cancelToken ?? this.cancelToken,
    );
  }

  @override
  String toString() {
    return 'FetchPayload(method: $method, uri: $uri, headers: $headers, body: $body)';
  }
}

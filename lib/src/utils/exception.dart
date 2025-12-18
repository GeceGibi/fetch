import 'package:fetch/src/core/payload.dart';

/// Fetch exception types
enum FetchExceptionType {
  /// Request was cancelled
  cancelled,

  /// Request was debounced
  debounced,

  /// Request was throttled
  throttled,

  /// Network error (connection, timeout, etc.)
  network,

  /// HTTP error (4xx, 5xx)
  http,
}

/// Custom exception class for Fetch operations
class FetchException implements Exception {
  FetchException({
    this.payload,
    Uri? uri,
    String? method,
    required this.type,
    String? message,
    this.error,
    this.stackTrace,
    this.statusCode,
  })  : _uri = uri,
        _method = method,
        _message = message;

  /// Request payload containing uri, method, headers, body (optional)
  final FetchPayload? payload;

  /// Error type
  final FetchExceptionType type;

  /// Custom error message (returns message, error string, or type name)
  String get message => _message ?? error?.toString() ?? type.name;
  final String? _message;

  /// Original error (if any)
  final Object? error;

  /// Stack trace
  final StackTrace? stackTrace;

  /// HTTP status code (if available)
  final int? statusCode;

  // Private fields for minimal exception creation
  final Uri? _uri;
  final String? _method;

  /// Request URI (from payload or direct)
  Uri? get uri => payload?.uri ?? _uri;

  /// Request method (from payload or direct)
  String? get method => payload?.method ?? _method;

  @override
  String toString() {
    final buffer = StringBuffer('FetchException: $type');
    if (uri != null) {
      buffer.write('\nURI: $uri');
    }
    if (method != null) {
      buffer.write('\nMethod: $method');
    }
    if (statusCode != null) {
      buffer.write('\nStatus: $statusCode');
    }
    if (_message != null) {
      buffer.write('\nMessage: $_message');
    }
    if (payload?.headers?.isNotEmpty ?? false) {
      buffer.write('\nHeaders: ${payload!.headers}');
    }
    if (payload?.body != null) {
      buffer.write('\nBody: ${payload!.body}');
    }
    if (error != null) {
      buffer.write('\nError: $error');
    }
    return buffer.toString();
  }
}

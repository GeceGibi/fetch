import 'package:fetch/src/core/payload.dart';

/// Fetch exception types
enum FetchExceptionType {
  /// Request was cancelled
  cancelled,

  /// Request was debounced
  debounced,

  /// Request was throttled
  throttled,

  /// Connection error
  connectionError,

  /// Timeout error
  timeout,

  /// HTTP error (4xx, 5xx)
  httpError,

  /// JSON parse error
  parseError,

  /// Unknown error
  unknown,
}

/// Custom exception class for Fetch operations
class FetchException implements Exception {
  FetchException({
    required this.payload,
    required this.type,
    String? message,
    this.error,
    this.stackTrace,
    this.statusCode,
  }) : _message = message;

  /// Request payload containing uri, method, headers, body
  final FetchPayload payload;

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

  /// Request URI
  Uri get uri => payload.uri;

  @override
  String toString() {
    final buffer = StringBuffer('FetchException: $type')
      ..write('\nURI: ${payload.uri}')
      ..write('\nMethod: ${payload.method}');
    if (statusCode != null) {
      buffer.write('\nStatus: $statusCode');
    }
    if (_message != null) {
      buffer.write('\nMessage: $_message');
    }
    if (payload.headers?.isNotEmpty ?? false) {
      buffer.write('\nHeaders: ${payload.headers}');
    }
    if (payload.body != null) buffer.write('\nBody: ${payload.body}');
    if (error != null) buffer.write('\nError: $error');
    return buffer.toString();
  }
}

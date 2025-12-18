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

  /// Custom error (extracted from response body, business logic errors)
  custom,
}

/// Custom exception class for Fetch operations
class FetchException implements Exception {
  FetchException({
    required this.type,
    this.payload,
    String? message,
    this.error,
    this.stackTrace,
    this.statusCode,
    this.responseBody,
  }) : _message = message;

  /// Request payload containing uri, method, headers, body (optional)
  final FetchPayload? payload;

  /// Error type
  final FetchExceptionType type;

  /// Response body (if available)
  ///
  /// This contains the raw response body from the server.
  /// Useful for extracting error messages from API responses.
  final String? responseBody;

  /// Custom error message
  ///
  /// Returns in order of priority:
  /// 1. Explicitly set message
  /// 2. Error object string representation
  /// 3. Exception type name
  String get message => _message ?? error?.toString() ?? type.name;
  final String? _message;

  /// Original error (if any)
  final Object? error;

  /// Stack trace
  final StackTrace? stackTrace;

  /// HTTP status code (if available)
  final int? statusCode;

  /// Request URI (from payload)
  Uri? get uri => payload?.uri;

  /// Request method (from payload)
  String? get method => payload?.method;

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
      buffer.write('\nRequest Body: ${payload!.body}');
    }
    if (responseBody != null) {
      buffer.write('\nResponse Body: $responseBody');
    }
    if (error != null) {
      buffer.write('\nError: $error');
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (uri != null) 'uri': uri.toString(),
      if (method != null) 'method': method,
      if (statusCode != null) 'statusCode': statusCode,
      'message': message,
      if (responseBody != null) 'responseBody': responseBody,
      if (payload != null) 'payload': payload!.toJson(),
      if (error != null) 'error': error.toString(),
    };
  }

  /// Creates a copy of this exception with the given fields replaced.
  FetchException copyWith({
    FetchExceptionType? type,
    FetchPayload? payload,
    String? message,
    Object? error,
    StackTrace? stackTrace,
    int? statusCode,
    String? responseBody,
  }) {
    return FetchException(
      type: type ?? this.type,
      payload: payload ?? this.payload,
      message: message ?? _message,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      statusCode: statusCode ?? this.statusCode,
      responseBody: responseBody ?? this.responseBody,
    );
  }
}

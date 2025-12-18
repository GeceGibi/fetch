/// Fetch exception types
enum FetchExceptionType {
  /// Request was cancelled
  cancelled,

  /// Request was debounced
  debounced,

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
    required this.message,
    required this.type,
    this.statusCode,
    this.data,
    this.stackTrace,
    this.uri,
  });

  /// Factory constructor for timeout errors
  factory FetchException.timeout(Uri uri, Duration timeout) {
    return FetchException(
      message: 'Request timeout after ${timeout.inSeconds}s',
      type: FetchExceptionType.timeout,
      uri: uri,
    );
  }

  /// Factory constructor for connection errors
  factory FetchException.connectionError(Uri uri, Object error) {
    return FetchException(
      message: 'Connection error: $error',
      type: FetchExceptionType.connectionError,
      uri: uri,
    );
  }

  /// Factory constructor for HTTP errors
  factory FetchException.httpError(
    int statusCode,
    Uri uri, {
    String? message,
    dynamic data,
  }) {
    return FetchException(
      message: message ?? 'HTTP error',
      type: FetchExceptionType.httpError,
      statusCode: statusCode,
      uri: uri,
      data: data,
    );
  }

  /// Factory constructor for parse errors
  factory FetchException.parseError(Object error, [StackTrace? stackTrace]) {
    return FetchException(
      message: 'Failed to parse response: $error',
      type: FetchExceptionType.parseError,
      stackTrace: stackTrace,
    );
  }

  /// Error message
  final String message;

  /// Error type
  final FetchExceptionType type;

  /// HTTP status code (if available)
  final int? statusCode;

  /// Request URI (if available)
  final Uri? uri;

  /// Response data (if available)
  final dynamic data;

  /// Stack trace
  final StackTrace? stackTrace;

  /// Is this an HTTP error?
  bool get isHttpError => type == FetchExceptionType.httpError;

  /// Is this a timeout error?
  bool get isTimeout => type == FetchExceptionType.timeout;

  /// Is this a connection error?
  bool get isConnectionError => type == FetchExceptionType.connectionError;

  /// Is this a client error? (4xx)
  bool get isClientError =>
      isHttpError &&
      statusCode != null &&
      statusCode! >= 400 &&
      statusCode! < 500;

  /// Is this a server error? (5xx)
  bool get isServerError =>
      isHttpError && statusCode != null && statusCode! >= 500;

  @override
  String toString() {
    final buffer = StringBuffer('FetchException: $message');
    if (statusCode != null) buffer.write(' (Status: $statusCode)');
    if (uri != null) buffer.write('\nURI: $uri');
    if (data != null) buffer.write('\nData: $data');
    return buffer.toString();
  }
}

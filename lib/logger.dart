part of 'fetch.dart';

/// Mixin that provides logging functionality for HTTP requests and responses.
///
/// This mixin adds logging capabilities to the Fetch class, including:
/// - Request/response logging
/// - Cache hit/miss logging
/// - Performance timing
/// - Structured log output
/// Represents a single fetch log entry.
///
/// This class encapsulates all the information about a single HTTP request/response
/// including timing, headers, body, and cache status.
class FetchLog {
  /// Creates a new FetchLog instance.
  ///
  /// [response] - The HTTP response to log
  /// [isCached] - Whether the response was retrieved from cache
  FetchLog(this.response, {this.isCached = false}) : date = DateTime.now();

  /// The HTTP response
  final FetchResponse response;

  /// When this log entry was created
  final DateTime? date;

  /// Whether the response was retrieved from cache
  final bool isCached;

  /// Returns a formatted string representation of the log entry.
  ///
  /// This method creates a structured, readable log output including:
  /// - Request URL and method
  /// - Response status and timing
  /// - Request and response headers
  /// - Request and response bodies
  /// - Cache status
  @override
  String toString() {
    final FetchResponse(:elapsed, :postBody) = response;

    final http.Response(
      :request,
      :statusCode,
      :reasonPhrase,
      :contentLength,
      :headers,
      :body,
    ) = response;

    final requestHeaders = request?.headers.entries ?? [];
    final String cacheNote;

    if (isCached) {
      cacheNote = ' (retrieved from cache)';
    } else {
      cacheNote = '';
    }

    return [
      ' ',
      '╭-- LOG BEGIN ${"-" * 40}',
      '├─url: ${request?.url}',
      '├─date: $date',
      '├─method: ${request?.method}',
      '├─status: $statusCode ($reasonPhrase)',
      '├─elapsed: ${elapsed?.inMilliseconds}ms$cacheNote',
      '├─content-length: $contentLength',
      '╰-headers:',
      '   ├──request:',
      for (final MapEntry(:key, :value) in requestHeaders)
        '   │   ├──$key: $value',
      '   ├──response:',
      for (final MapEntry(:key, :value) in headers.entries)
        '   │   ├──$key: $value',
      if (postBody != null) '├─post-body: $postBody',
      '├─response-body: $body',
      '╰─ LOG END ${"─" * 40} ',
      ' ',
    ].join('\n');
  }
}

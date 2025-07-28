part of 'fetch.dart';

/// Represents a single fetch log entry.
///
/// This class encapsulates all the information about a single HTTP request/response
/// including timing, headers, body, and cache status.
class FetchLog<R extends FetchResponse> {
  /// Creates a new FetchLog instance.
  ///
  /// [response] - The HTTP response to log
  /// [isCached] - Whether the response was retrieved from cache
  /// [maxBodyLength] - Maximum body length to log
  FetchLog(
    this.response, {
    this.isCached = false,
    this.maxBodyLength,
    this.postBody,
    this.elapsed,
  }) : date = DateTime.now();

  /// The HTTP response
  final http.Response response;

  /// When this log entry was created
  final DateTime date;

  /// Whether the response was retrieved from cache
  final bool isCached;

  /// Maximum body length to log
  final int? maxBodyLength;

  /// The original request body
  final Object? postBody;

  /// Request duration
  final Duration? elapsed;

  /// Truncate text if it's too long
  String _truncate(String text) {
    if (maxBodyLength == null || text.length <= maxBodyLength!) return text;
    return '${text.substring(0, maxBodyLength)}... (truncated)';
  }

  /// Get cache status string
  String get _cacheStatus => isCached ? ' (CACHED)' : '';

  /// Get status indicator
  String get _statusIndicator {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return '✅';
    if (status >= 300 && status < 400) return '🔄';
    if (status >= 400 && status < 500) return '⚠️';
    return '❌';
  }

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
    final http.Response(
      :request,
      :headers,
      :body,
      :statusCode,
      :reasonPhrase,
      :contentLength
    ) = response;

    final reqHeaderEntries = request?.headers.entries ?? [];

    final requestHeaders = StringBuffer();
    final responseHeaders = StringBuffer();

    if (reqHeaderEntries.isEmpty) {
      requestHeaders.write('│    ╰─ (none)');
    } else {
      for (var i = reqHeaderEntries.length - 1; i >= 0; i--) {
        final MapEntry(:key, :value) = reqHeaderEntries.elementAt(i);
        requestHeaders.write('│    ${i == 0 ? '╰' : '├'}─ $key: $value\n');
      }
    }

    if (headers.isEmpty) {
      responseHeaders.write('│    ╰─ (none)');
    } else {
      for (var i = headers.entries.length - 1; i >= 0; i--) {
        final MapEntry(:key, :value) = headers.entries.elementAt(i);
        responseHeaders.write('│    ${i == 0 ? '╰' : '├'}─ $key: $value\n');
      }
    }

    final responseBody = _truncate(body);

    final requestBody =
        postBody != null ? _truncate(postBody.toString()) : null;

    return [
      '',
      '╭─ $_statusIndicator FETCH LOG $_cacheStatus ${"─" * 35}',
      '├─ Date: ${date.toIso8601String()}',
      '├─ URL: ${request?.url}',
      '├─ Method: ${request?.method}',
      '├─ Elapsed: ${elapsed?.inMilliseconds}ms',
      '├─ Status: $statusCode ($reasonPhrase)',
      '├─ Content-Length: $contentLength',
      '├─ Request Headers:',
      requestHeaders.toString(),
      '├─ Response Headers:',
      responseHeaders.toString(),

      ///
      if (requestBody != null) ...[
        '├─ Request Body:',
        '│    ╰─ $requestBody',
      ],

      ///
      '├─ Response Body:',
      '│    ╰─ $responseBody',
      '╰──${"─" * 50}',
      '',
    ].join('\n');
  }
}

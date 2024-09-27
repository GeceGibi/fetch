part of 'fetch.dart';

mixin FetchLogger {
  final fetchLogs = <FetchLog>[];

  ///
  void log(
    FetchResponse response, {
    bool isCached = false,
    bool enableLogs = false,
  }) {
    final fetchLog = FetchLog(
      response,
      isCached: isCached,
    );

    fetchLogs.add(fetchLog);

    if (enableLogs) {
      _printer(fetchLog);
    }
  }

  void _printer(Object? data) {
    final pattern = RegExp('.{1,800}');

    for (final match in pattern.allMatches('$data')) {
      // ignore: avoid_print
      print(match.group(0));
    }
  }
}

class FetchLog {
  FetchLog(this.response, {this.isCached = false}) : date = DateTime.now();

  final FetchResponse response;
  final DateTime? date;
  final bool isCached;

  @override
  String toString() {
    final FetchResponse(
      :elapsed,
      :postBody,
    ) = response;

    final http.Response(
      :request,
      :statusCode,
      :reasonPhrase,
      :contentLength,
      :headers,
      :body,
    ) = response.response;

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

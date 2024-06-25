part of 'fetch.dart';

mixin FetchLogger {
  final fetchLogs = <FetchLog>[];

  ///
  void log(
    FetchResponse response, {
    Object? postBody,
    bool isCached = false,
    bool enableLogs = false,
  }) {
    final fetchLog = FetchLog(
      response,
      isCached: isCached,
      body: postBody,
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
  FetchLog(
    this.response, {
    required this.body,
    this.isCached = false,
  }) : date = DateTime.now();

  final FetchResponse response;
  final DateTime? date;
  final Object? body;
  final bool isCached;

  @override
  String toString() {
    final requestHeaders = response.request?.headers.entries ?? [];

    final String cacheNote;

    if (isCached) {
      cacheNote = ' (retrieved from cache)';
    } else {
      cacheNote = '';
    }

    return [
      ' ',
      '╭-- LOG BEGIN ${"-" * 40}',
      '├─url: ${response.request?.url}',
      '├─date: $date',
      '├─method: ${response.request?.method}',
      if (response.request?.method == 'POST')
        '├─body(${body.runtimeType}): $body',
      '├─status: ${response.statusCode} (${response.reasonPhrase})',
      if (response.error != null) ...[
        '├─error: ${response.error?.body}',
        '├─stack: ${response.error?.stackTrace}',
      ] else ...[
        '├─elapsed: ${response.elapsed.inMilliseconds}ms$cacheNote',
        '├─content-length: ${response.contentLength}',
        '╰-headers:',
        '   ├──request:',
        for (final MapEntry(:key, :value) in requestHeaders)
          '   │   ├──$key: $value',
        '   ├──response:',
        for (final MapEntry(:key, :value) in response.headers.entries)
          '   │   ├──$key: $value',
        if (body != null) '├─post-body: $body',
        '├─response-body: ${response.body}',
      ],
      '╰─ LOG END ${"─" * 40} ',
      ' ',
    ].join('\n');
  }
}

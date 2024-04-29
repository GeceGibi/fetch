part of 'fetch.dart';

mixin FetchLogger {
  bool _isLogsEnabled = true;

  final fetchLogs = <FetchLog>[];

  void logError(Object? error, StackTrace stackTrace) {
    if (!_isLogsEnabled) {
      return;
    }

    final output = [
      '├─error: $error',
      '├─stack-trace: $stackTrace',
    ].join('\n');

    printer(output);
  }

  ///
  void log(
    FetchResponse response, {
    Object? postBody,
    bool isCached = false,
  }) {
    final fetchLog = FetchLog(
      response,
      isCached: isCached,
    );

    fetchLogs.add(fetchLog);

    if (!_isLogsEnabled) {
      return;
    }

    printer(fetchLog);
  }

  void printer(Object? data) {
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
    this.body,
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
      cacheNote = ' (cached)';
    } else {
      cacheNote = '';
    }

    return [
      '╭-- LOG BEGIN ${"-" * 40}',
      '├─url: ${response.request?.url}',
      '├─date: $date',
      '├─method: ${response.request?.method}',
      '├─status: ${response.statusCode}',
      '├─reason-phrase: ${response.reasonPhrase}',
      '├─content-length: ${response.contentLength}',
      '├─elapsed: ${response.elapsed.inMilliseconds}ms$cacheNote',
      '╰-headers:',
      '   ├──request:',
      for (final MapEntry(:key, :value) in requestHeaders)
        '   │   ├──$key: $value',
      '   ├──response:',
      for (final MapEntry(:key, :value) in response.headers.entries)
        '   │   ├──$key: $value',
      if (body != null) '├─post-body: $body',
      '├─response-body: ${response.body}',
      '╰─ LOG END ${"─" * 40} ',
    ].join('\n');
  }
}

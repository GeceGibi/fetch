part of fetch;

class FetchLogger {
  final _onFetchController = StreamController<FetchLog>.broadcast();
  final _onErrorController = StreamController<FetchLog>.broadcast();
  final fetchLogs = <FetchLog>[];

  ///
  void _log(
    HttpResponse response,
    Duration elapsedTime, {
    Object? postBody,
    bool isCached = false,
  }) {
    final fetchLog = FetchLog.fromHttpResponse(
      response,
      elapsed: elapsedTime,
      postBody: postBody,
      isCached: isCached,
    );

    _onFetchController.add(fetchLog);
    fetchLogs.add(fetchLog);
    printer(fetchLog);
  }

  void _logError(Object? event, StackTrace? stackTrace) {
    final fetchLog = FetchLog.error(event, stackTrace);
    _onErrorController.add(fetchLog);
    fetchLogs.add(fetchLog);
    printer(fetchLog);
  }
}

void printer(Object? data) {
  // for (final line in '$data'.split('\n')) {
  //   print(line);
  // }

  final pattern = RegExp('.{1,800}');
  pattern.allMatches('$data').forEach(
        (match) => print(match.group(0)),
      );
}

class FetchLog {
  FetchLog.error(Object? event, this.stackTrace)
      : status = null,
        method = null,
        url = null,
        date = null,
        requestHeaders = const {},
        responseHeaders = const {},
        response = null,
        postBody = null,
        error = event.toString(),
        elapsed = null,
        isCached = false;

  FetchLog.fromHttpResponse(
    HttpResponse response, {
    this.postBody,
    this.elapsed,
    this.isCached = false,
  })  : status = response.statusCode,
        method = response.request?.method ?? '-',
        url = response.request?.url.toString() ?? '-',
        date = DateTime.now(),
        requestHeaders = response.request?.headers ?? const {},
        responseHeaders = response.headers,
        response = response.body,
        error = null,
        stackTrace = null;

  final int? status;
  final String? method;
  final String? url;
  final DateTime? date;
  final Object? postBody;
  final Map<String, String>? requestHeaders;
  final Map<String, String>? responseHeaders;
  final dynamic response;
  final dynamic error;
  final StackTrace? stackTrace;
  final Duration? elapsed;
  final bool isCached;

  @override
  String toString() {
    const prefix = 'LOG BEGIN >>>>>>>>>>>>>>>>';
    const suffix = '<<<<<<<<<<<<<<<<<< LOG END';

    if (error != null) {
      return [
        '\n',
        prefix,
        'error: $error',
        'stack trace: ',
        '$stackTrace',
        suffix,
        '\n',
      ].join('\n');
    }

    final reqHeaders = requestHeaders?.entries ?? [];
    final resHeaders = responseHeaders?.entries ?? [];

    final String cacheNote;

    if (isCached) {
      cacheNote = ' (cached)';
    } else {
      cacheNote = '';
    }

    return [
      '\n',
      prefix,
      'url: $url',
      'date: $date',
      'method: $method',
      'status: $status',
      'elapsed: ${elapsed?.inMilliseconds}ms$cacheNote',
      'headers:',
      '├──request:',
      ...[
        for (final header in reqHeaders) '│    ├─${header.key}: ${header.value}'
      ],
      '├──response:',
      ...[
        for (final header in resHeaders) '│    ├─${header.key}: ${header.value}'
      ],
      if (postBody != null) ...['post body:', '$postBody'],
      'response-body:',
      response,
      suffix,
      '\n',
    ].join('\n');
  }
}

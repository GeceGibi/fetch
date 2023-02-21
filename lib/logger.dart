part of fetch;

abstract class FetchLogger {
  final _onFetchController = StreamController<FetchLog>.broadcast();
  final fetchLogs = <FetchLog>[];

  var enableLogger = true;

  ///
  void _log(HttpResponse response, Duration elapsedTime) {
    final fetchLog = FetchLog.fromHttpResponse(
      response,
      elapsed: elapsedTime,
    );

    _onFetchController.add(fetchLog);

    fetchLogs.add(fetchLog);

    if (enableLogger) {
      print(fetchLog);
      return;
    }
  }

  void _logError(Object? event, StackTrace stackTrace) {
    final fetchLog = FetchLog.error(event, stackTrace);

    _onFetchController.add(fetchLog);

    fetchLogs.add(fetchLog);

    if (enableLogger) {
      print(fetchLog);
      return;
    }
  }
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
        elapsed = null;

  FetchLog.fromHttpResponse(
    HttpResponse response, {
    this.postBody,
    this.elapsed,
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

  @override
  String toString() {
    const prefix = 'LOG BEGIN >>>>>>>>>>>>>>>>';
    const suffix = '<<<<<<<<<<<<<<<<<< LOG END';

    if (error != null) {
      return [
        prefix,
        'error: $error',
        'stack trace: ',
        '$stackTrace',
        suffix,
      ].join('\n');
    }

    final reqHeaders = requestHeaders?.entries ?? [];
    final resHeaders = responseHeaders?.entries ?? [];

    return [
      '',
      prefix,
      'url: $url',
      'date: $date',
      'method: $method',
      'status: $status',
      'elapsed: ${elapsed?.inMilliseconds}ms',
      'headers:',
      '├──request:',
      ...[
        for (final header in reqHeaders) '│    ├─${header.key}: ${header.value}'
      ],
      '├──response:',
      ...[
        for (final header in resHeaders) '│    ├─${header.key}: ${header.value}'
      ],
      if (postBody != null) ...[
        'post body:',
        if (postBody is Map)
          for (final body in (postBody as Map).entries)
            '├─${body.key}: ${body.value}'
        else
          '├─$postBody'
      ],
      'raw:',
      response,
      suffix,
      '',
    ].join('\n');
  }
}

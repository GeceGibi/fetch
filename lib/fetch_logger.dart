part of fetch;

class FetchLog {
  FetchLog({
    required this.date,
    required this.method,
    required this.requestHeaders,
    required this.response,
    required this.responseHeaders,
    required this.status,
    required this.url,
    this.postBody,
  });

  FetchLog.error({
    required this.url,
    required this.method,
    required this.requestHeaders,
    this.postBody,
    Object? error,
  })  : status = -1,
        date = DateTime.now(),
        responseHeaders = {},
        response = error;

  FetchLog.fromHttpResponse(HttpResponse httpResponse, [this.postBody])
      : status = httpResponse.statusCode,
        method = httpResponse.request?.method ?? 'UNKNOWN',
        url = httpResponse.request?.url.toString() ?? 'UNKNOWN',
        date = DateTime.now(),
        requestHeaders = httpResponse.request?.headers ?? const {},
        responseHeaders = httpResponse.headers,
        response = httpResponse.body;

  final int status;
  final String method;
  final String url;
  final DateTime date;
  final FetchParams? postBody;
  final FetchParams<String> requestHeaders;
  final FetchParams<String> responseHeaders;
  final dynamic response;

  @override
  String toString() {
    return [
      '',
      'LOG BEGIN >>>>>>>>>>>>>>>>',
      'url: $url',
      'date: $date',
      'method: $method',
      'status: $status',
      'headers:',
      '├──request:',
      ...[
        for (final header in requestHeaders.entries)
          '│    ├─${header.key}: ${header.value}'
      ],
      '├──response:',
      ...[
        for (final header in responseHeaders.entries)
          '│    ├─${header.key}: ${header.value}'
      ],
      if (postBody != null) ...[
        'post body:',
        for (final body in postBody!.entries) '├─${body.key}: ${body.value}'
      ],
      'raw:',
      response,
      '<<<<<<<<<<<<<<<<<<< LOG END',
      '',
    ].join('\n');
  }
}

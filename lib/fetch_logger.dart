part of fetch;

void _fetchLogger(
  HttpResponse response,
  FetchConfig config, [
  FetchParams? body,
]) {
  if (!config.isLoggerEnabled) {
    return;
  }

  final date = DateTime.now();

  final requestHeaders = [];
  response.request!.headers.forEach((key, value) {
    requestHeaders.add('│    ├─$key: $value');
  });

  final responseHeaders = [];
  response.headers.forEach((key, value) {
    responseHeaders.add('│    ├─$key: $value');
  });

  final requestBody = [];
  if (body != null) {
    requestBody.add('post body:');
    body.forEach((key, value) {
      requestBody.add('├─$key: $value');
    });
  }

  final lines = [
    '',
    'LOG BEGIN >>>>>>>>>>>>>>>>',
    'url: ${response.request!.url}',
    'date: $date',
    'method: ${response.request!.method}',
    'status: ${response.statusCode}',
    'headers:',
    '├──request:',
    ...requestHeaders,
    '├──response:',
    ...responseHeaders,
    ...requestBody,
    'raw:',
    response.body,
    '<<<<<<<<<<<<<<<<<<< LOG END',
    '',
  ];

  for (final line in lines) {
    print(line);
  }
}

part of fetch;

void _logger(http.Response response, [FetchParams? body]) {
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
    requestHeaders.join('\n'),
    '├──response:',
    responseHeaders.join('\n'),
    requestBody.join('\n'),
    'raw-response-body:',
    response.body,
    '<<<<<<<<<<<<<<<<<<< LOG END',
    '',
  ];

  print(lines.join('\n'));
}

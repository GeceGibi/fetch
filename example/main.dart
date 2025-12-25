import 'package:via/via.dart';

void main() async {
  print('--- Via Example Suite ---');

  await runBasicExample();
  await runPostExample();
  await runErrorHandlingExample();
  await runCancellationExample();

  print('\n--- All Examples Completed ---');
}

/// [1] Basic GET Request & Auto-Mapping
Future<void> runBasicExample() async {
  print('\n[1] Simple GET & JSON Mapping');
  final via = Via(
    base: Uri.parse('https://httpbin.org'),
    pipelines: [AppLogger()],
  );

  final response = await via.get('/get', queryParams: {'id': '123'});

  // Use .to() for easy mapping without manual jsonDecode
  final id = await response.to((json) => json['args']['id'] as String);
  print('Mapped ID from response: $id');
}

/// [2] POST Request with Complex Body (Map)
Future<void> runPostExample() async {
  print('\n[2] POST Request with Body');
  final via = Via(
    base: Uri.parse('https://httpbin.org'),
    pipelines: [AppLogger()],
  );

  // Map values are automatically stringified for form-data
  await via.post('/post', {
    'status': 'success',
    'code': 200,
    'is_test': true,
  });
}

/// [3] Custom Validation & Global Error Handling
Future<void> runErrorHandlingExample() async {
  print('\n[3] Error Handling & Global onError');
  
  final via = Via(
    base: Uri.parse('https://httpbin.org'),
    // Global callback for any error in the lifecycle
    onError: (error) => print('Global Handler Caught: ${error.type.name}'),
    pipelines: [
      AppLogger(),
      // Custom validator to throw on 4xx/5xx
      ViaResponseValidatorPipeline(
        validator: (res) =>
            res.statusCode >= 400 ? 'HTTP Error ${res.statusCode}' : null,
      ),
    ],
  );

  try {
    await via.get('/status/404');
  } on ViaException catch (_) {
    // Exception is already handled by global onError and logger
  }
}

/// [4] Manual Request Cancellation
Future<void> runCancellationExample() async {
  print('\n[4] Request Cancellation');
  final via = Via(base: Uri.parse('https://httpbin.org'), pipelines: [AppLogger()]);
  final cts = CancelToken();

  // Start a delayed request and cancel it immediately
  final future = via.get('/delay/2', cancelToken: cts);
  cts.cancel();

  try {
    await future;
  } on ViaException catch (e) {
    print('Caught expected cancellation: ${e.message}');
  }
}

/// A simple custom logger by overriding onLog
class AppLogger extends ViaLoggerPipeline {
  @override
  void onLog(Object event) {
    switch (event) {
      case final ViaRequest r:
        print('🚀 Request: ${r.method.value} ${r.uri}');

      case final ViaBaseResult res:
        print(
          '✅ Response: ${res.statusCode} (${res.elapsed?.inMilliseconds}ms)',
        );
        
      case final ViaException e:
        print('❌ Error: ${e.message}');
    }
  }
}

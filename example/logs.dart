import 'package:via/via.dart';

/// A professional logger that overrides [onLog] to print detailed info
class MyPrettyLogger extends ViaLoggerPipeline {
  @override
  void onLog(Object event) {
    switch (event) {
      case final ViaRequest r:
        print('🚀 Request: ${r.method} ${r.uri}');
        print('💻 cURL: ${r.toCurl()}');
      case final ViaResult result:
        print(
          '✅ Response: ${result.statusCode} (${result.elapsed?.inMilliseconds}ms)',
        );
      case final ViaException error:
        print('❌ Error: ${error.message}');
    }
  }
}

Future<void> main() async {
  print('--- [1] Silent Logging (History only) ---');
  final silentLogger = ViaLoggerPipeline();
  final viaSilent = Via(
    base: Uri.parse('https://httpbin.org'),
    pipelines: [silentLogger],
  );

  await viaSilent.get('/get');
  print('Total events recorded: ${silentLogger.logs.length}');

  print('\n--- [2] Pretty Logging (Override onLog) ---');
  final viaPretty = Via(
    base: Uri.parse('https://httpbin.org'),
    pipelines: [MyPrettyLogger()],
  );
  await viaPretty.get('/status/200');

  print('\n--- [3] Toggling Logger ---');
  final logger = MyPrettyLogger()..enabled = false;

  final viaToggle = Via(
    base: Uri.parse('https://httpbin.org'),
    pipelines: [logger],
  );

  print('Logger disabled, no output expected below:');
  await viaToggle.get('/get');
  print('Logs in history: ${logger.logs.length}');
}

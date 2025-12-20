import 'package:via/via.dart';

/// A professional logger that overrides [onLog] to print detailed info
class MyPrettyLogger extends ViaLoggerPipeline {
  @override
  void onLog(Object event) {
    switch (event) {
      case final ViaRequest r:
        print('🚀 Request: ${r.method} ${r.uri}');
        print('💻 cURL: ${r.toCurl()}');
      case final ViaResult r:
        print(
          '✅ Response: ${r.response.statusCode} (${r.elapsed?.inMilliseconds}ms)',
        );
      case final ViaException e:
        print('❌ Error: ${e.message}');
    }
  }
}

void main() async {
  print('--- [1] Silent Logging (History only) ---');
  final silentLogger = ViaLoggerPipeline();
  final viaSilent = Via(
    base: Uri.parse('https://httpbin.org'),
    executor: ViaExecutor(pipelines: [silentLogger]),
  );

  await viaSilent.get('/get');
  print('Total events recorded: ${silentLogger.logs.length}');

  print('\n--- [2] Pretty Logging (Override onLog) ---');
  final viaPretty = Via(
    base: Uri.parse('https://httpbin.org'),
    executor: ViaExecutor(pipelines: [MyPrettyLogger()]),
  );
  await viaPretty.get('/status/200');

  print('\n--- [3] Toggling Logger ---');
  final logger = MyPrettyLogger()..enabled = false;

  final viaToggle = Via(
    base: Uri.parse('https://httpbin.org'),
    executor: ViaExecutor(pipelines: [logger]),
  );

  print('Logger disabled, no output expected below:');
  await viaToggle.get('/get');
  print('Logs in history: ${logger.logs.length}');
}

import 'dart:isolate';
import 'package:via/via.dart';

Future<void> main() async {
  final via = Via<ViaResult>(
    base: Uri.parse('https://httpbin.org'),
    executor: ViaExecutor(
      // Run the network request in a background isolate
      // This is perfect for complex apps to keep the UI 100% smooth
      runner: (method, request) => Isolate.run(() => method(request)),
    ),
  );

  print('--- Isolate Execution Test ---');
  final result = await via.get('/get');
  print('Request completed in background isolate.');
  print('Status: ${result.response.statusCode}');
}

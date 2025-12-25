import 'dart:isolate';
import 'package:via/via.dart';

Future<void> main() async {
  final via = Via<ViaResult>(
    base: Uri.parse('https://httpbin.org'),
    executor: ViaExecutor(
      // Run the network request in a background isolate
      // Note: When using isolates, we must buffer the response before sending it back
      // because streams cannot be transferred between isolates directly.
      runner: (executorMethod, viaRequest) => Isolate.run(() async {
        final result = await executorMethod(viaRequest);

        if (viaRequest.isStream) {
          return result as ViaResultStream;
        } else {
          return result as ViaResult;
        }
      }),
    ),
  );

  print('--- Isolate Execution Test ---');
  final result = await via.get('/get');
  print('Request completed in background isolate.');
  print('Status: ${result.statusCode}');
}

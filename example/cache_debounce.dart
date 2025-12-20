import 'package:via/via.dart';

void main() async {
  final via = Via(
    base: Uri.parse('https://httpbin.org'),
    executor: ViaExecutor(
      pipelines: [
        // Cache GET requests for 5 seconds
        ViaCachePipeline(duration: Duration(seconds: 5)),
        // Prevent rapid duplicate requests (last one wins)
        ViaDebouncePipeline(duration: Duration(milliseconds: 500)),
      ],
    ),
  );

  print('--- Cache & Debounce Test ---');

  print('\n[1] First request (Network)...');
  await via.get('/get');

  print('\n[2] Second request (Should come from Cache)...');
  await via.get('/get');

  print('\n[3] Sending 3 rapid requests (Debounce active)...');
  // These will fire, but only the last one will actually execute
  via.get('/get').then((_) => print('Request A done'));
  via.get('/get').then((_) => print('Request B done'));
  via.get('/get').then((_) => print('Request C done (Actual execution)'));
}

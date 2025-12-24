import 'package:via/via.dart';

Future<void> main() async {
  final via = Via(base: Uri.parse('https://httpbin.org'));
  final cancelToken = CancelToken();

  print('--- Cancellation Test ---');

  // Start a long-running request
  final call = via.get('/delay/5', cancelToken: cancelToken);

  call.then((_) {
    print('Request finished (Should not happen)');
  }).catchError((Object error) {
    if (error is ViaException && error.type == .cancelled) {
      print('✅ Request successfully cancelled!');
    }
  });

  // Cancel after 1 second
  await Future<void>.delayed(Duration(seconds: 1));
  print('Cancelling request...');
  cancelToken.cancel();
}

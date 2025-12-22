import 'package:via/via.dart';

Future<void> main() async {
  final via = Via(base: Uri.parse('https://httpbin.org'));
  final cancelToken = CancelToken();

  print('--- Cancellation Test ---');

  // Start a long-running request
  final request = via.get('/delay/5', cancelToken: cancelToken);

  request.then((_) {
    print('Request finished (Should not happen)');
  }).catchError((Object e) {
    if (e is ViaException && e.type == ViaError.cancelled) {
      print('✅ Request successfully cancelled!');
    }
  });

  // Cancel after 1 second
  await Future<void>.delayed(Duration(seconds: 1));
  print('Cancelling request...');
  cancelToken.cancel();
}

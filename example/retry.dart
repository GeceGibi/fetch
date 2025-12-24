import 'package:via/via.dart';

Future<void> main() async {
  final via = Via(
    base: Uri.parse('https://httpbin.org'),
    executor: ViaExecutor(
      // [Default Behavior]
      // By default, errorIf treats any status code outside 200-299 as an error.
      // This automatically triggers the retry mechanism for 500, 404, etc.
      retry: ViaRetry(
        maxAttempts: 3,
        retryDelay: const Duration(seconds: 1),
        retryIf: (error, attempt) {
          print('⚠️ Attempt $attempt failed: ${error.message}. Retrying...');
          return true; // Retry on every error
        },
      ),
    ),
  );

  print('--- Retry Test Started (Simulating 500 Error) ---');

  try {
    // httpbin.org/status/500 returns a 500 status code.
    // Via automatically treats this as an error and retries 3 times.
    await via.get('/status/500');
  } on ViaException catch (error) {
    print('\n❌ Request failed after 3 attempts.');
    print('Final Status Code: ${error.response?.statusCode}');
    print('Error Message: ${error.message}');
  }
}

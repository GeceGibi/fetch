import 'package:via/via.dart';

void main() async {
  final via = Via(
    base: Uri.parse('https://httpbin.org'),
    executor: ViaExecutor(
      // [Default Behavior]
      // By default, errorIf treats any status code outside 200-299 as an error.
      // This automatically triggers the retry mechanism for 500, 404, etc.
      retry: ViaRetry(
        maxAttempts: 3,
        retryDelay: Duration(seconds: 1),
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
  } on ViaException catch (e) {
    print('\n❌ Request failed after 3 attempts.');
    print('Final Status Code: ${e.response?.statusCode}');
    print('Error Message: ${e.message}');
  }
}

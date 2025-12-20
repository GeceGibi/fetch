import 'package:via/via.dart';

void main() async {
  // Simple initialization
  final via = Via(base: Uri.parse('https://api.example.com'));

  // Quick Start Example
  print('Welcome to Via! Check the example/ folder for more detailed tests:');
  print('- example/basic.dart: Simple GET/POST');
  print('- example/logs.dart: Professional logging with cURL');
  print('- example/retry.dart: Retry mechanism');
  print('- example/pipeline.dart: Custom pipelines');
  print('- example/isolate.dart: Background execution');
  print('- example/cache_debounce.dart: Performance features');
  print('- example/cancel.dart: Request cancellation');
  print('- example/custom_result.dart: Custom response models');

  try {
    final result = await via.get('/users/1');
    print('User: ${result.response.body}');
  } catch (e) {
    print('Check out the examples above to see Via in action!');
  }
}

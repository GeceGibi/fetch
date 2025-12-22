import 'basic.dart' as basic;
import 'cache_debounce.dart' as cache;
import 'cancel.dart' as cancel;
import 'custom_result.dart' as custom;
import 'isolate.dart' as isolate;
import 'logs.dart' as logs;
import 'pipeline.dart' as pipeline;
import 'retry.dart' as retry;

void main() async {
  print('=========================================');
  print('🚀 RUNNING ALL VIA EXAMPLES');
  print('=========================================\n');

  print('1. BASIC REQUESTS');
  await basic.main();
  print('\n-----------------------------------------\n');

  print('2. LOGGING');
  await logs.main();
  print('\n-----------------------------------------\n');

  print('3. RETRY MECHANISM');
  await retry.main();
  print('\n-----------------------------------------\n');

  print('4. PIPELINES');
  await pipeline.main();
  print('\n-----------------------------------------\n');

  print('5. CACHE & DEBOUNCE');
  await cache.main();
  print('\n-----------------------------------------\n');

  print('6. REQUEST CANCELLATION');
  await cancel.main();
  print('\n-----------------------------------------\n');

  print('7. CUSTOM RESULT MODELS');
  await custom.main();
  print('\n-----------------------------------------\n');

  print('8. ISOLATE EXECUTION');
  await isolate.main();
  
  print('\n=========================================');
  print('✅ ALL EXAMPLES COMPLETED SUCCESSFULLY');
  print('=========================================');
}

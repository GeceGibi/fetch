import 'dart:async';

import 'package:via/via.dart';

void main() async {
  await basicExample();
  await retryExample();
}

/// Basic GET request
Future<void> basicExample() async {
  print('\n=== Basic Example ===');
  final via = Via<ViaResult>(
    base: Uri.parse('https://httpbin.org'),
  );
  final result = await via.get('/get');
  print('Status: ${result.toJson()}');
}

/// Debounce - only last request executes
Future<void> debounceExample() async {
  print('\n=== Debounce Example ===');

  final via = Via<ViaResult>(
    base: Uri.parse('https://httpbin.org'),
    executor: ViaExecutor(
      pipelines: [
        DebouncePipeline(duration: Duration(seconds: 1)),
      ],
    ),
  );

  print('Sending 5 rapid requests (only last will execute)...');

  Future<void>? lastRequest;
  for (var i = 1; i <= 5; i++) {
    final request = via.get('/get').then((r) {
      print('✓ Request $i completed: ${r.response.statusCode}');
    }).catchError((Object e) {
      if (e is ViaException && e.type == ViaError.debounced) {
        print('✗ Request $i debounced');
      }
    });

    if (i == 5) lastRequest = request;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  // Wait for the last request to complete
  await lastRequest;
}

/// Throttle - only first request within duration executes
Future<void> throttleExample() async {
  print('\n=== Throttle Example ===');

  final via = Via<ViaResult>(
    base: Uri.parse('https://httpbin.org'),
    executor: ViaExecutor(
      pipelines: [
        ThrottlePipeline(duration: Duration(seconds: 2)),
      ],
    ),
  );

  print('Sending 5 rapid requests (only first will execute)...');

  for (var i = 1; i <= 5; i++) {
    via.get('/get').then((r) {
      print('✓ Request $i completed: ${r.response.statusCode}');
    }).catchError((Object e) {
      if (e is ViaException && e.type == ViaError.throttled) {
        print('✗ Request $i throttled');
      }
    });

    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  // Wait for throttle window to clear
  await Future<void>.delayed(const Duration(seconds: 3));
}

/// Retry on failure with token refresh support
Future<void> retryExample() async {
  print('\n=== Retry Example ===');

  final via = Via(
    base: Uri.parse('https://api.gece.dev'),
    executor: ViaExecutor(
      pipelines: [
        ThrowPipeline(),
      ],
      retry: ViaRetry(
        maxAttempts: 3,
        retryIf: (error, attempt) async {
          print('Attempt $attempt failed: ${error.message}, retrying...');
          return true;
        },
      ),
    ),
  );

  try {
    final result = await via.get('/info');
    print(result.toJson());
  } on ViaException catch (e) {
    print('✗ Failed after 3 attempts');
    print('  Error: ${e.toJson()}');
  }
}

class ThrowPipeline extends ViaPipeline<ViaResult> {
  @override
  FutureOr<ViaResult> onResult(ViaResult result) async {
    await Future<void>.delayed(const Duration(seconds: 1));

    throw ViaException.custom(
      request: result.request,
      message: 'Forced error',
    );
  }
}

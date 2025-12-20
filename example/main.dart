import 'dart:async';

import 'package:fetch/fetch.dart';

void main() async {
  await basicExample();
  await retryExample();
}

/// Basic GET request
Future<void> basicExample() async {
  print('\n=== Basic Example ===');
  final fetch = Fetch<FetchResult>(
    base: Uri.parse('https://httpbin.org'),
  );
  final result = await fetch.get('/get');
  print('Status: ${result.toJson()}');
}

/// Debounce - only last request executes
Future<void> debounceExample() async {
  print('\n=== Debounce Example ===');

  final fetch = Fetch<FetchResult>(
    base: Uri.parse('https://httpbin.org'),
    executor: Executor(
      pipelines: [
        DebouncePipeline(duration: Duration(seconds: 1)),
      ],
    ),
  );

  print('Sending 5 rapid requests (only last will execute)...');

  Future<void>? lastRequest;
  for (var i = 1; i <= 5; i++) {
    final request = fetch.get('/get').then((r) {
      print('✓ Request $i completed: ${r.response.statusCode}');
    }).catchError((Object e) {
      if (e is FetchException && e.type == FetchError.debounced) {
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

  final fetch = Fetch<FetchResult>(
    base: Uri.parse('https://httpbin.org'),
    executor: Executor(
      pipelines: [
        ThrottlePipeline(duration: Duration(seconds: 2)),
      ],
    ),
  );

  print('Sending 5 rapid requests (only first will execute)...');

  for (var i = 1; i <= 5; i++) {
    fetch.get('/get').then((r) {
      print('✓ Request $i completed: ${r.response.statusCode}');
    }).catchError((Object e) {
      if (e is FetchException && e.type == FetchError.throttled) {
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

  final fetch = Fetch(
    base: Uri.parse('https://api.gece.dev'),
    executor: Executor(
      pipelines: [
        ThrowPipeline(),
      ],
      retry: FetchRetry(
        maxAttempts: 3,
        retryIf: (error, attempt) async {
          print('Attempt $attempt failed: ${error.message}, retrying...');
          return true;
        },
      ),
    ),
  );

  try {
    final result = await fetch.get('/info');
    print(result.toJson());
  } on FetchException catch (e) {
    print('✗ Failed after 3 attempts');
    print('  Error: ${e.toJson()}');
  }
}

class ThrowPipeline extends FetchPipeline<FetchResult> {
  @override
  FutureOr<FetchResult> onResult(FetchResult result) async {
    await Future<void>.delayed(const Duration(seconds: 1));

    throw FetchException.custom(
      request: result.request,
      message: 'Forced error',
    );
  }
}

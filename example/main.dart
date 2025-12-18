import 'dart:convert';

import 'package:fetch/fetch.dart';

void main() async {
  // Basic usage
  await basicExample();

  // Debounce example
  await debounceExample();

  // Throttle example
  await throttleExample();

  // Retry example
  await retryExample();

  // Interceptor example
  await interceptorExample();

  // Error handling example
  await errorHandlingExample();

  // Cache example
  await cacheExample();

  // Cancel example
  await cancelExample();

  // Executor example (isolate-based, not available on web)
  await executorExample();
}

/// Basic GET request
Future<void> basicExample() async {
  print('\n=== Basic Example ===');

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
  );

  final response = await fetch.get('/get');
  print('Status: ${response.response.statusCode}');
}

/// Debounce - only last request executes
Future<void> debounceExample() async {
  print('\n=== Debounce Example ===');

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
    interceptors: [
      DebounceInterceptor(duration: const Duration(seconds: 1)),
    ],
  );

  print('Sending 5 rapid requests (only last will execute)...');

  Future<void>? lastRequest;
  for (var i = 1; i <= 5; i++) {
    final request = fetch.get('/get').then((r) {
      print('✓ Request $i completed: ${r.response.statusCode}');
    }).catchError((Object e) {
      if (e is FetchException && e.type == FetchExceptionType.debounced) {
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

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
    interceptors: [
      ThrottleInterceptor(duration: const Duration(seconds: 2)),
    ],
  );

  print('Sending 5 rapid requests (only first will execute)...');

  for (var i = 1; i <= 5; i++) {
    fetch.get('/get').then((r) {
      print('✓ Request $i completed: ${r.response.statusCode}');
    }).catchError((Object e) {
      if (e is FetchException && e.type == FetchExceptionType.throttled) {
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

  var token = 'expired-token';

  Future<void> refreshToken() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    token = 'fresh-token';
    print('  Token refreshed!');
  }

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
    maxAttempts: 3,
    retryDelay: const Duration(seconds: 1),
    retryIf: (error) async {
      // Refresh token on 401
      if (error.statusCode == 401) {
        await refreshToken();
        return true;
      }
      // Retry on server errors
      return error.statusCode != null && error.statusCode! >= 500;
    },
    interceptors: [
      AuthInterceptor(getToken: () => token),
      LogInterceptor(logRequest: false),
    ],
  );

  print('Attempting request to /status/500 (will retry 3 times)...');
  try {
    await fetch.get('/status/500');
  } on FetchException catch (e) {
    print('✗ Failed after 3 attempts');
    print('  Error: ${e.message}');
  }
}

/// Interceptors for logging and auth
Future<void> interceptorExample() async {
  print('\n=== Interceptor Example ===');

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
    interceptors: [
      LogInterceptor(),
      AuthInterceptor(getToken: () => 'my-token'),
    ],
  );

  await fetch.get('/headers');
}

/// Error handling with onError callback
Future<void> errorHandlingExample() async {
  print('\n=== Error Handling Example ===');

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
    onError: (error) {
      print('✗ Global error handler: ${error.message}');
    },
  );

  print('Attempting request to /status/404...');
  try {
    await fetch.get('/status/404');
  } on FetchException catch (e) {
    print('  Caught: ${e.message}');
  }
}

/// Cache responses
Future<void> cacheExample() async {
  print('\n=== Cache Example ===');

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
    interceptors: [
      CacheInterceptor(duration: const Duration(seconds: 10)),
      LogInterceptor(logRequest: false),
    ],
  );

  print('First request (not cached)');
  await fetch.get('/get');

  print('Second request (from cache)');
  await fetch.get('/get');
}

/// Cancel requests
Future<void> cancelExample() async {
  print('\n=== Cancel Example ===');

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
  );

  final token = CancelToken();

  // Start request and handle cancellation
  final future = fetch.get('/delay/5', cancelToken: token);

  // Cancel after 500ms
  await Future<void>.delayed(const Duration(milliseconds: 500));
  token.cancel();

  // Wait for the cancelled request to complete
  try {
    await future;
  } on FetchException catch (e) {
    if (e.type == FetchExceptionType.cancelled) {
      print('Request cancelled successfully');
    }
  }
}

/// Executor example - using isolate for CPU-intensive operations
Future<void> executorExample() async {
  print('\n=== Executor Example ===');

  // Isolate executor - request runs in separate isolate
  final fetchIsolate = Fetch<Map<String, dynamic>>(
    base: Uri.parse('https://httpbin.org'),
    executor: const RequestExecutor.isolate(),
    transform: (response) {
      print('Transform in main isolate...');
      return jsonDecode(response.response.body) as Map<String, dynamic>;
    },
  );

  final isolateData = await fetchIsolate.get('/get');
  print('Request executed in isolate: ${isolateData['url']}');
}

import 'package:fetch/fetch.dart';

void main() async {
  // Basic usage
  await basicExample();

  // Debounce example
  await debounceExample();

  // Retry example
  await retryExample();

  // Interceptor example
  await interceptorExample();

  // Cache example
  await cacheExample();

  // Cancel example
  await cancelExample();
}

/// Basic GET request
Future<void> basicExample() async {
  print('\n=== Basic Example ===');

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
  );

  final response = await fetch.get('/get');
  print('Status: ${response.response.statusCode}');

  fetch.dispose();
}

/// Debounce - only last request executes
Future<void> debounceExample() async {
  print('\n=== Debounce Example ===');

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
    debounceOptions: const DebounceOptions(duration: Duration(seconds: 1)),
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
  fetch.dispose();
}

/// Retry on failure
Future<void> retryExample() async {
  print('\n=== Retry Example ===');

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
    retryOptions: RetryOptions(
      maxAttempts: 3,
      retryDelay: Duration(seconds: 1),
      retryIf: (error) {
        return error.isServerError;
      },
    ),
    interceptors: [
      LogInterceptor(logRequest: false),
    ],
  );

  print('Attempting request to /status/500 (will retry 3 times)...');
  try {
    await fetch.get('/status/500');
  } on FetchException catch (e) {
    print('✗ Failed after ${fetch.retryOptions.maxAttempts} attempts');
    print('  Error: ${e.message} (${e.statusCode})');
  }

  fetch.dispose();
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

  fetch.dispose();
}

/// Cache responses
Future<void> cacheExample() async {
  print('\n=== Cache Example ===');

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
    cacheOptions: const CacheOptions(duration: Duration(seconds: 10)),
  );

  print('First request (not cached)');
  await fetch.get('/get');

  print('Second request (from cache)');
  await fetch.get('/get');

  fetch.dispose();
}

/// Cancel requests
Future<void> cancelExample() async {
  print('\n=== Cancel Example ===');

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
  );

  final token = CancelToken();

  fetch.get('/delay/5', cancelToken: token).catchError((Object e) {
    if (e is FetchException && e.type == FetchExceptionType.cancelled) {
      print('Request cancelled');
    }
    return Future<FetchResponse>.error(e);
  });

  await Future<void>.delayed(const Duration(milliseconds: 500));
  token.cancel();

  fetch.dispose();
}

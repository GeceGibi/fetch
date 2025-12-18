import 'dart:convert';
import 'dart:isolate';

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

  // Pipeline example
  await pipelineExample();

  // Error handling example
  await errorHandlingExample();

  // Response validation example (business logic errors)
  await responseValidatorExample();

  // Cache example
  await cacheExample();

  // Cancel example
  await cancelExample();

  // Runner example (isolate-based, not available on web)
  await runnerExample();
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
    executor: Executor(
      pipelines: [
        AuthPipeline(getToken: () => token),
        LogPipeline(logRequest: false),
      ],
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
    ),
  );

  print('Attempting request to /status/500 (will retry 3 times)...');
  try {
    await fetch.get('/status/500');
  } on FetchException catch (e) {
    print('✗ Failed after 3 attempts');
    print('  Error: ${e.message}');
  }
}

/// Pipelines for logging and auth
Future<void> pipelineExample() async {
  print('\n=== Pipeline Example ===');

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
    executor: Executor(
      pipelines: [
        LogPipeline(),
        AuthPipeline(getToken: () => 'my-token'),
      ],
    ),
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
      // Response body is now available in the error
      if (error.responseBody != null) {
        print('  Response Body: ${error.responseBody}');
      }
    },
  );

  print('Attempting request to /status/404...');
  try {
    await fetch.get('/status/404');
  } on FetchException catch (e) {
    print('  Caught: ${e.message}');
    print('  Status Code: ${e.statusCode}');
  }
}

/// Response validation for business logic errors using Pipeline
///
/// Sometimes APIs return 200 OK but with success: false in the body.
/// Use ResponseValidatorPipeline to handle those cases globally.
Future<void> responseValidatorExample() async {
  print('\n=== Response Validator Pipeline Example ===');

  // Example API that returns 200 but with error in body
  // Real APIs might return: {"success": false, "error": "User not found"}

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
    executor: Executor(
      pipelines: [
        // Validate responses for business logic errors
        ResponseValidatorPipeline(
          validator: (response) {
            try {
              final json = jsonDecode(response.response.body);

              if (json is Map<String, dynamic>) {
                // Pattern 1: success: false
                if (json['success'] == false) {
                  return json['error'] as String? ?? 'Request failed';
                }

                // Pattern 2: error field exists
                if (json.containsKey('error') && json['error'] != null) {
                  return json['error'] as String;
                }
              }
            } catch (_) {
              // Not JSON, ignore
            }

            return null; // Valid response
          },
        ),
      ],
    ),
    onError: (error) {
      if (error.type == FetchExceptionType.custom) {
        print('✗ Business logic error: ${error.message}');
      }
    },
  );

  print('Request to /get (success case)...');
  try {
    final response = await fetch.get('/get');
    print('✓ Success: ${response.response.statusCode}');
  } on FetchException catch (e) {
    print('✗ Error: ${e.message}');
  }
}

/// Cache responses
Future<void> cacheExample() async {
  print('\n=== Cache Example ===');

  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
    executor: Executor(
      pipelines: [
        CachePipeline(duration: Duration(seconds: 10)),
        LogPipeline(logRequest: false),
      ],
    ),
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

/// Runner example - using isolate for CPU-intensive operations
Future<void> runnerExample() async {
  print('\n=== Runner Example ===');

  // Custom runner - request execution in separate isolate
  final fetchIsolate = Fetch<Map<String, dynamic>>(
    base: Uri.parse('https://httpbin.org'),
    executor: Executor(
      runner: (method, payload) => Isolate.run(() => method(payload)),
    ),
    transform: (response) {
      print('Transform in main isolate...');
      return jsonDecode(response.response.body) as Map<String, dynamic>;
    },
  );

  final isolateData = await fetchIsolate.get('/get');
  print('Request executed in isolate: ${isolateData['url']}');
}

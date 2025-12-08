import 'dart:async';
import 'dart:isolate';

import 'package:fetch/fetch.dart';

/// Custom response class that demonstrates response transformation.
///
/// This class shows how to create a custom response type with
/// additional functionality like isolate-based JSON parsing.
class IResponse extends FetchResponse {
  /// Creates a new IResponse instance.
  ///
  /// [response] - The original HTTP response
  /// [jsonBody] - The parsed JSON body
  /// [elapsed] - Request duration
  /// [encoding] - Character encoding
  /// [postBody] - Original request body
  IResponse(super.response) : super();

  /// Converts the response to a List using isolate-based parsing.
  ///
  /// [E] - The type of list elements
  ///
  /// Returns a List<E> parsed in a separate isolate for better performance.
  @override
  FutureOr<List<E>> asList<E>() {
    return Isolate.run(
      () => super.asList<E>(),
      debugName: 'asList<$E>',
    );
  }

  /// Converts the response to a Map using isolate-based parsing.
  ///
  /// [K] - The type of map keys
  /// [V] - The type of map values
  ///
  /// Returns a Map<K, V> parsed in a separate isolate for better performance.
  @override
  FutureOr<Map<K, V>> asMap<K, V>() {
    return Isolate.run(
      () => super.asMap<K, V>(),
      debugName: 'asMap<$K, $V>',
    );
  }
}

/// Test function for cancel functionality.
Future<void> testCancel() async {
  print('\n=== Testing Cancel Functionality ===');
  
  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://httpbin.org'),
  );

  // Test 1: Cancel before request starts
  print('\nTest 1: Cancel before request');
  final token1 = CancelToken();
  token1.cancel();
  
  try {
    await fetch.get('/delay/5', cancelToken: token1);
    print('❌ Should have thrown CancelledException');
  } on CancelledException catch (e) {
    print('✅ Correctly threw CancelledException: $e');
  } catch (e) {
    print('❌ Unexpected exception: $e');
  }

  // Test 2: Cancel during request
  print('\nTest 2: Cancel during request');
  final token2 = CancelToken();
  
  // Use a longer delay endpoint (10 seconds)
  final requestFuture = fetch.get('https://httpstat.us/200?sleep=10000', cancelToken: token2);
  
  // Cancel after 500ms
  Future.delayed(const Duration(milliseconds: 500), () {
    print('Cancelling request after 500ms...');
    token2.cancel();
  });
  
  try {
    await requestFuture;
    print('❌ Should have thrown CancelledException');
  } on CancelledException catch (e) {
    print('✅ Request cancelled successfully: $e');
  } catch (e) {
    print('❌ Unexpected exception: $e');
  }

  // Test 3: Normal request without cancel
  print('\nTest 3: Normal request without cancel');
  try {
    final response = await fetch.get('https://httpstat.us/200');
    print('✅ Normal request completed: ${response.response.statusCode}');
  } on CancelledException catch (e) {
    print('✅ Request cancelled successfully: $e');
  } catch (e) {
    print('❌ Normal request failed: $e');
  }

  print('\n=== Cancel Tests Completed ===\n');
}

/// Main function demonstrating the Fetch library usage.
///
/// This example shows various features of the Fetch library including:
/// - Base URL configuration
/// - Header building
/// - Request overriding
/// - Response transformation
/// - Caching
/// - Logging
void main(List<String> args) async {
  // Test cancel functionality first
  await testCancel();

  print('=== Starting Normal Examples ===\n');

  // Create a Fetch instance with custom configuration
  final fetch = Fetch(
    base: Uri.parse('https://api.gece.dev'),
    headerBuilder: () {
      return {
        'content-type': 'application/json',
      };
    },
    // onLog: (response) {
    //   print(response.elapsed);
    // },
    override: (payload, method) {
      // Example of request overriding - modifying POST requests
      if (payload.method == 'POST') {
        payload = payload.copyWith(body: 'SELAM');
      }

      // Execute the request in a separate isolate
      return Isolate.run(() => method(payload));
    },
    transform: (response) {
      // Transform the response to our custom type
      return IResponse(response.response);
    },
  );

  try {
    // Make a GET request
    final response = await fetch.get('info', enableLogs: true);

    // Convert response to strongly-typed map
    final data = await response.asMap<String, dynamic>();

    // Print the result
    print('Response data: $data');
  } catch (e) {
    print('Error: $e');
  }

  // Example of caching usage (commented out for brevity)
  // final cachedResponse = await fetch.get(
  //   'https://raw.githubusercontent.com/json-iterator/test-data/master/large-file.json',
  //   cacheOptions: CacheOptions(duration: Duration(seconds: 10)),
  //   queryParams: {
  //     'foo2': 1,
  //   },
  // );

  // Example of multiple requests with timing
  // final stopwatch = Stopwatch()..start();
  // final response1 = await fetch.get('/info');
  // final response2 = await fetch.get('/info');
  // print('First request: ${response1.elapsed}');
  // print('Second request: ${response2.elapsed}');
  // print('Total time: ${stopwatch.elapsed}');
}

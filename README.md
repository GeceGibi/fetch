# Fetch

A comprehensive HTTP client library for Dart/Flutter applications with built-in caching, logging, and response transformation capabilities.

## Features

- **Type-safe HTTP client** with generic response transformation
- **Built-in caching** with configurable strategies and expiration
- **Request debouncing** to prevent rapid duplicate requests
- **Auto-retry** with exponential backoff for failed requests
- **Interceptors** for request/response/error handling
- **Custom exceptions** with detailed error types
- **Global error handler** for centralized error management
- **Request/response logging** with detailed timing and metadata
- **Request overriding** for intercepting and modifying requests
- **Header building** with automatic merging
- **Timeout handling** with configurable durations
- **JSON parsing** with type-safe conversion methods
- **Isolate support** for background processing

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  fetch: ^3.1.0+3
```

## Quick Start

```dart
import 'package:fetch/fetch.dart';

void main() async {
  final fetch = Fetch<Map<String, dynamic>>(
    base: Uri.parse('https://api.example.com'),
    transform: (response) => response.jsonBody as Map<String, dynamic>,
  );

  final data = await fetch.get('/users');
  print(data);
}
```

## Basic Usage

### Simple GET Request

```dart
final fetch = Fetch<FetchResponse>();

final response = await fetch.get('https://api.example.com/users');
print(response.statusCode);
print(response.body);
```

### With Base URL

```dart
final fetch = Fetch<FetchResponse>(
  base: Uri.parse('https://api.example.com'),
);

// This will request https://api.example.com/users
final response = await fetch.get('/users');
```

### With Query Parameters

```dart
final response = await fetch.get(
  '/users',
  queryParams: {
    'page': 1,
    'limit': 10,
  },
);
```

### POST Request with Body

```dart
final response = await fetch.post(
  '/users',
  {
    'name': 'John Doe',
    'email': 'john@example.com',
  },
);
```

## Advanced Features

### Response Transformation

```dart
class User {
  final String name;
  final String email;
  
  User.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        email = json['email'];
}

final fetch = Fetch<List<User>>(
  transform: (response) {
    final List<dynamic> usersJson = response.asList();
    return usersJson.map((json) => User.fromJson(json)).toList();
  },
);

final users = await fetch.get('/users');
```

### Caching

```dart
final fetch = Fetch<FetchResponse>(
  cacheOptions: CacheOptions(
    duration: Duration(minutes: 5),
    strategy: CacheStrategy.fullUrl,
  ),
);

// This response will be cached for 5 minutes
final response = await fetch.get('/users');
```

### Custom Headers

Use interceptors to add headers globally. For example, `AuthInterceptor` adds `Authorization` automatically:

```dart
final fetch = Fetch<FetchResponse>(
  interceptors: [
    AuthInterceptor(getToken: () => 'your-token'),
  ],
);
```

### Request Overriding

To modify requests before sending, implement a custom interceptor:

```dart
class CustomHeaderInterceptor extends Interceptor {
  @override
  InterceptorResult onRequest(FetchPayload payload) {
    return ContinueRequest(
      payload.copyWith(
        headers: {
          ...?payload.headers,
          'X-Custom-Header': 'value',
        },
      ),
    );
  }
}

final fetch = Fetch<FetchResponse>(
  interceptors: [CustomHeaderInterceptor()],
);
```

### Interceptors

Interceptors allow you to intercept and modify requests, responses, and errors:

```dart
final fetch = Fetch<FetchResponse>(
  interceptors: [
    // Log all requests and responses
    LogInterceptor(),
    
    // Add authentication token to requests
    AuthInterceptor(
      getToken: () async => await storage.getToken(),
    ),
    
    // Handle errors globally
    ErrorInterceptor(
      onErrorCallback: (error) {
        print('Error: ${error.message}');
        // Send to error tracking service
      },
    ),
  ],
);
```

Create custom interceptors:

```dart
class MyCustomInterceptor extends Interceptor {
  @override
  Future<FetchPayload> onRequest(FetchPayload payload) async {
    // Modify request before sending
    print('Sending request to ${payload.uri}');
    return payload;
  }

  @override
  Future<FetchResponse> onResponse(FetchResponse response) async {
    // Process response before returning
    print('Received response: ${response.response.statusCode}');
    return response;
  }

  @override
  Future<void> onError(FetchException error) async {
    // Handle errors
    print('Error occurred: ${error.message}');
  }
}
```

### Error Handling

Detaylı exception handling:

```dart
try {
  await fetch.get('/api/endpoint');
} on FetchException catch (e) {
  if (e.isTimeout) {
    print('Request timeout');
  } else if (e.isServerError) {
    print('Server error: ${e.statusCode}');
  } else if (e.isClientError) {
    print('Client error: ${e.statusCode}');
  } else if (e.isConnectionError) {
    print('Network error');
  }
}
```

Global error handler using interceptor:

```dart
final fetch = Fetch<FetchResponse>(
  interceptors: [
    ErrorInterceptor(
      onErrorCallback: (error) {
        // All errors come here
        logger.error(error);
        showErrorDialog(error.message);
      },
    ),
  ],
);
```

### Caching with CacheInterceptor

Cache responses to reduce network calls:

```dart
final fetch = Fetch<FetchResponse>(
  interceptors: [
    CacheInterceptor(
      duration: Duration(minutes: 5),
      strategy: CacheStrategy.fullUrl,
    ),
  ],
);

// First request hits the network
await fetch.get('/users');

// Second request uses cached response
await fetch.get('/users');
```

### Debouncing with DebounceInterceptor

Prevent rapid duplicate requests - only the last request executes:

```dart
final fetch = Fetch<FetchResponse>(
  interceptors: [
    DebounceInterceptor(duration: Duration(milliseconds: 500)),
  ],
);

// Only the last request will execute
for (var i = 0; i < 5; i++) {
  fetch.get('/search?q=flutter');
  await Future.delayed(Duration(milliseconds: 100));
}
```

### Throttling with ThrottleInterceptor

Limit request rate - only the first request within the duration executes:

```dart
final fetch = Fetch<FetchResponse>(
  interceptors: [
    ThrottleInterceptor(duration: Duration(seconds: 1)),
  ],
);

// Only the first request will execute, others are throttled
for (var i = 0; i < 5; i++) {
  fetch.get('/api/data');
  await Future.delayed(Duration(milliseconds: 100));
}
```

### Retry with Executors

Use `RetryExecutor` to add automatic retry logic:

```dart
final fetch = Fetch<FetchResponse>(
  executor: RetryExecutor(
    executor: const DefaultExecutor(),
    maxAttempts: 3,
    retryDelay: Duration(seconds: 1),
    retryIf: (error) => error.isServerError || error.isTimeout,
  ),
);

// Will retry up to 3 times on server errors or timeouts
await fetch.get('/api/endpoint');
```

### Complete Pipeline Example

Combine multiple interceptors and executors:

```dart
final fetch = Fetch<FetchResponse>(
  interceptors: [
    LogInterceptor(),
    CacheInterceptor(duration: Duration(minutes: 5)),
    ThrottleInterceptor(duration: Duration(seconds: 1)), // Rate limiting
    AuthInterceptor(getToken: () => getToken()),
  ],
  executor: RetryExecutor(
    executor: const IsolateExecutor(),
    maxAttempts: 3,
  ),
  onError: (error) => logError(error),
);
```

## API Reference

### Fetch Class

The main HTTP client class with the following constructor parameters:

- `base` - Base URI for all requests
- `timeout` - Request timeout duration (default: 30 seconds)
- `interceptors` - List of interceptors forming the request/response pipeline
- `onError` - Global error handler called for all errors
- `transform` - Function to transform responses
- `executor` - Request executor strategy (default: DefaultExecutor)

### HTTP Methods

- `get(endpoint, {queryParams, headers, cancelToken})`
- `post(endpoint, body, {queryParams, headers, cancelToken})`
- `put(endpoint, body, {queryParams, headers, cancelToken})`
- `delete(endpoint, body, {queryParams, headers, cancelToken})`
- `patch(endpoint, body, {queryParams, headers, cancelToken})`
- `head(endpoint, {queryParams, headers, cancelToken})`

### Executors

**RequestExecutor** - Base interface for request execution strategies:
- `DefaultExecutor` - Executes requests in main isolate
- `IsolateExecutor` - Executes requests in separate isolate (not supported on web)
- `RetryExecutor` - Wraps any executor with retry logic

**RetryExecutor parameters:**
- `executor` - The underlying executor to wrap
- `maxAttempts` - Maximum retry attempts (default: 3)
- `retryDelay` - Delay between retries (default: 1 second)
- `retryIf` - Function to determine if error should be retried

Example:
```dart
// Simple retry
final fetch = Fetch(
  executor: RetryExecutor(
    executor: const DefaultExecutor(),
    maxAttempts: 3,
  ),
);

// Retry + Isolate
final fetch = Fetch(
  executor: RetryExecutor(
    executor: const IsolateExecutor(),
    maxAttempts: 3,
  ),
);
```

### Built-in Interceptors

**LogInterceptor** - Logs requests and responses:
- `logRequest` - Whether to log requests (default: true)
- `logResponse` - Whether to log responses (default: true)

**AuthInterceptor** - Adds authentication token to requests:
- `getToken` - Function that returns the auth token

**CacheInterceptor** - Caches responses to reduce network calls:
- `duration` - How long to cache responses
- `strategy` - Cache strategy (CacheStrategy.fullUrl or CacheStrategy.urlWithoutQuery)
- `canCache` - Function to determine if a response can be cached

**DebounceInterceptor** - Prevents rapid duplicate requests (only last executes):
- `duration` - Debounce duration (each new request resets the timer)

**ThrottleInterceptor** - Limits request rate (only first executes):
- `duration` - Throttle duration (subsequent requests within window are rejected)

### FetchException

Hata türleri:
- `FetchExceptionType.cancelled` - İstek iptal edildi
- `FetchExceptionType.debounced` - İstek debounce edildi
- `FetchExceptionType.connectionError` - Bağlantı hatası
- `FetchExceptionType.timeout` - Timeout hatası
- `FetchExceptionType.httpError` - HTTP hatası (4xx, 5xx)
- `FetchExceptionType.parseError` - JSON parse hatası
- `FetchExceptionType.unknown` - Bilinmeyen hata

Yardımcı metodlar:
- `isHttpError` - HTTP hatası mı?
- `isTimeout` - Timeout hatası mı?
- `isConnectionError` - Bağlantı hatası mı?
- `isClientError` - Client hatası mı? (4xx)
- `isServerError` - Server hatası mı? (5xx)

### FetchResponse

Enhanced HTTP response with additional features:

- `isSuccess` - Whether the response indicates success (200-299)
- `jsonBody` - Parsed JSON body
- `elapsed` - Request duration
- `asMap<K, V>()` - Convert to strongly-typed Map
- `asList<E>()` - Convert to strongly-typed List

## Examples

See the `example.dart` file for comprehensive usage examples including:

- Custom response types
- Isolate-based processing
- Request overriding
- Response transformation
- Caching strategies
- Debouncing
- Retry mechanism
- Interceptors
- Error handling with FetchException
- Global error handler

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

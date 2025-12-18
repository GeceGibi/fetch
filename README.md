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

```dart
final fetch = Fetch<FetchResponse>(
  headerBuilder: () => {
    'Authorization': 'Bearer your-token',
    'Content-Type': 'application/json',
  },
);
```

### Request Overriding

```dart
final fetch = Fetch<FetchResponse>(
  override: (payload, method) async {
    // Modify the request before sending
    if (payload.method == 'POST') {
      payload = payload.copyWith(
        headers: {
          ...payload.headers ?? {},
          'X-Custom-Header': 'value',
        },
      );
    }
    
    return method(payload);
  },
);
```

### Logging

```dart
final fetch = Fetch<FetchResponse>(
  enableLogs: true,
);

// Enable logging for specific requests
final response = await fetch.get('/users', enableLogs: true);
```

### Debouncing

Hızlı tekrarlayan isteklerde sadece son isteği çalıştır:

```dart
final fetch = Fetch<FetchResponse>(
  debounceOptions: DebounceOptions(duration: Duration(milliseconds: 500)),
);

// 5 hızlı istek - sadece son çalışır
for (var i = 0; i < 5; i++) {
  fetch.get('/search?q=flutter');
  await Future.delayed(Duration(milliseconds: 100));
}
```

### Retry Mechanism

Otomatik yeniden deneme ile hata toleransı:

```dart
final fetch = Fetch<FetchResponse>(
  retryOptions: RetryOptions(
    maxAttempts: 3,
    retryDelay: Duration(seconds: 1),
    retryDelayFactor: 2.0, // Exponential backoff
    retryIf: (error) => error.isServerError || error.isTimeout,
  ),
);

// Server hatası durumunda 3 kez dener
await fetch.get('/api/endpoint');
```

### Interceptors

Request/response/error için middleware:

```dart
final fetch = Fetch<FetchResponse>(
  interceptors: [
    // Log interceptor
    LogInterceptor(),
    
    // Auth interceptor
    AuthInterceptor(
      getToken: () async => await storage.getToken(),
    ),
    
    // Custom interceptor
    MyCustomInterceptor(),
  ],
);
```

Kendi interceptor'ınızı oluşturun:

```dart
class MyCustomInterceptor extends Interceptor {
  @override
  Future<FetchPayload> onRequest(FetchPayload payload) async {
    // İstek öncesi
    print('Sending request to ${payload.uri}');
    return payload;
  }

  @override
  Future<FetchResponse> onResponse(FetchResponse response) async {
    // Response sonrası
    print('Received response: ${response.response.statusCode}');
    return response;
  }

  @override
  Future<void> onError(FetchException error) async {
    // Hata durumunda
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

Global error handler:

```dart
final fetch = Fetch<FetchResponse>(
  onError: (error, stackTrace) {
    // Tüm hatalar buraya düşer
    logger.error(error, stackTrace);
    showErrorDialog(error.message);
  },
);
```

## API Reference

### Fetch Class

The main HTTP client class with the following constructor parameters:

- `base` - Base URI for all requests
- `headerBuilder` - Function to build headers for each request
- `encoding` - Character encoding (default: utf8)
- `enableLogs` - Whether to enable logging (default: true)
- `timeout` - Request timeout duration (default: 30 seconds)
- `cacheOptions` - Cache configuration options
- `debounceOptions` - Debounce configuration options
- `retryOptions` - Retry configuration options
- `interceptors` - List of interceptors
- `onError` - Global error handler
- `transform` - Function to transform responses
- `override` - Function to override requests before sending

### HTTP Methods

- `get(endpoint, {queryParams, headers, cacheOptions, debounceOptions, retryOptions, enableLogs})`
- `post(endpoint, body, {queryParams, headers, cacheOptions, debounceOptions, retryOptions, enableLogs})`
- `put(endpoint, body, {queryParams, headers, cacheOptions, debounceOptions, retryOptions, enableLogs})`
- `delete(endpoint, body, {queryParams, headers, cacheOptions, debounceOptions, retryOptions, enableLogs})`
- `patch(endpoint, body, {queryParams, headers, cacheOptions, debounceOptions, retryOptions, enableLogs})`
- `head(endpoint, {queryParams, headers, cacheOptions, debounceOptions, retryOptions, enableLogs})`

### CacheOptions

- `duration` - How long to cache responses
- `strategy` - Cache strategy (CacheStrategy.fullUrl or CacheStrategy.urlWithoutQuery)
- `canCache` - Function to determine if a response can be cached

### DebounceOptions

- `duration` - Debounce süresi (son çağrıdan sonra beklenecek süre)
- `enabled` - Debounce aktif mi (duration > 0 ise aktif)

### RetryOptions

- `maxAttempts` - Maksimum deneme sayısı (varsayılan: 3)
- `retryDelay` - Retry'lar arası bekleme süresi (varsayılan: 1 saniye)
- `retryDelayFactor` - Her retry'da delay çarpanı (exponential backoff için)
- `retryIf` - Retry yapılıp yapılmayacağını belirleyen fonksiyon

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

# Via

A modern, type-safe HTTP client library for Dart/Flutter applications.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  via: ^1.0.0
```

Then install the package:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:via/via.dart';

final via = Via<ViaResult>(
  base: Uri.parse('https://api.example.com'),
);

final result = await via.get('/users');
print('Status: ${result.response.statusCode}');
print('Body: ${result.response.body}');
```

### JSON Responses

```dart
final result = await via.get('/users');

// Parse as Map
final Map<String, dynamic> data = await result.asMap<String, dynamic>();

// Parse as List
final List<dynamic> items = await result.asList<dynamic>();
```

### POST Request

```dart
final result = await via.post(
  '/users',
  {'name': 'John', 'email': 'john@example.com'},
);
```

## Features

### Authentication Pipeline

```dart
final via = Via<ViaResult>(
  base: Uri.parse('https://api.example.com'),
  executor: ViaExecutor(
    pipelines: [
      AuthPipeline(
        getToken: () async => await getAuthToken(),
      ),
    ],
  ),
);
```

### Caching

```dart
final cachePipeline = CachePipeline<ViaResult>(
  duration: Duration(minutes: 5),
);

final via = Via<ViaResult>(
  executor: ViaExecutor(
    pipelines: [cachePipeline],
  ),
);
```

### Retry

```dart
final via = Via<ViaResult>(
  executor: ViaExecutor(
    retry: ViaRetry(
      maxAttempts: 3,
      retryDelay: Duration(seconds: 2),
    ),
  ),
);
```

### Request Cancellation

```dart
final cancelToken = CancelToken();
final future = via.get('/endpoint', cancelToken: cancelToken);

// Cancel request
cancelToken.cancel();
```

### Error Handling

```dart
try {
  final result = await via.get('/endpoint');
} on ViaException catch (e) {
  print('Error: ${e.message}');
}
```

## HTTP Methods

```dart
await via.get('/endpoint');
await via.post('/endpoint', {'key': 'value'});
await via.put('/endpoint', {'key': 'value'});
await via.delete('/endpoint');
await via.patch('/endpoint', {'key': 'value'});
await via.head('/endpoint');
```

## Examples

For more examples, check the `example/` directory.

## License

MIT License. See the `LICENSE` file for details.

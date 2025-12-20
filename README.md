# 🛣️ Via

**A modern, type-safe HTTP client for Dart & Flutter.**

Via is a lightweight networking engine built for simplicity and performance. It features a pipeline architecture, built-in resilience, and type-safe response handling.

---

## 🚀 Quick Start

### Installation

Add `via` to your `pubspec.yaml`:

```yaml
dependencies:
  via: ^1.0.0
```

### Simple GET Request

```dart
import 'package:via/via.dart';

void main() async {
  final via = Via(base: Uri.parse('https://api.example.com'));
  final result = await via.get('/users/1');
  
  final user = await result.asMap<String, dynamic>();
  print('User Name: ${user['name']}');
}
```

---

## 🔥 Key Features

### 🛠️ Pipeline Architecture
Use pipelines for logging, authentication, and more. 
- **`ViaLoggerPipeline`**: Silent by default. Records history in `logs` list with `maxEntries` limit. Override `onLog` for custom printing.
- **`ViaCachePipeline`**: In-memory caching with `maxEntries` (FIFO) to prevent memory leaks.

```dart
final via = Via(
  executor: ViaExecutor(
    pipelines: [
      ViaLoggerPipeline(),
      ViaCachePipeline(duration: Duration(minutes: 5), maxEntries: 100),
    ],
  ),
);
```

### 🛡️ Retry Logic
Automatic retry on failures. By default, any status code outside 200-299 triggers the retry mechanism. Customize this with `errorIf`.

```dart
final via = Via(
  executor: ViaExecutor(
    // Default errorIf treats non-2xx as errors
    errorIf: (result) => !result.isSuccess, 
    retry: ViaRetry(maxAttempts: 3),
  ),
);
```

### 🛑 Request Cancellation & cURL
Easily cancel requests or convert them to cURL commands for debugging.

```dart
final request = ViaRequest(uri: Uri.parse('...'), method: 'GET');
print(request.toCurl()); // Returns: curl -X GET "..."

final cancelToken = CancelToken();
via.get('/data', cancelToken: cancelToken);
cancelToken.cancel();
```

### 💎 Custom Result Types
Extend `ViaResult` and use a transformation pipeline to create your own type-safe response models.

```dart
class MyResponse extends ViaResult {
  MyResponse({required super.request, required super.response});
  bool get hasError => response.body.contains('error');
}

class MyResponsePipeline extends ViaPipeline<MyResponse> {
  @override
  MyResponse onResult(ViaResult result) => MyResponse(
    request: result.request, 
    response: result.response,
  );
}

// Initialize with your custom type and its transformation pipeline
final via = Via<MyResponse>(
  executor: ViaExecutor(
    pipelines: [MyResponsePipeline()],
  ),
);

final result = await via.get('/data');
print('Has Error: ${result.hasError}');
```

---

## ⚖️ License
This project is licensed under the MIT License.

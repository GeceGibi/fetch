# 🛣️ Via

**A modern, type-safe HTTP & WebSocket client for Dart & Flutter.**

Via is a lightweight networking engine built for simplicity and performance. It features a pipeline architecture, built-in resilience, and type-safe response handling.

---

## 🚀 Quick Start

### Installation

Add `via` to your `pubspec.yaml`:

```yaml
dependencies:
  via: ^1.3.0
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

### Multipart File Upload

```dart
final result = await via.post(
  '/upload',
  {'type': 'avatar'},
  files: {
    'image': ViaFile.fromBytes(myBytes, filename: 'avatar.png'),
  },
);
```

### WebSocket Support

```dart
final socket = await via.socket('/ws');

socket.stream.listen((message) => print('Received: $message'));
socket.send('Hello!');
```

---

## 🔥 Key Features

### 🛠️ Pipeline Architecture
Use pipelines for logging, authentication, and more. 
- **`ViaLoggerPipeline`**: Records history in `logs` list. Override `onLog` for custom printing.
- **`ViaCachePipeline`**: In-memory caching with `maxEntries` (FIFO) limit.

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
Automatic retry on failures. Customize what constitutes an error with `errorIf`.

```dart
final via = Via(
  executor: ViaExecutor(
    errorIf: (result) => !result.isSuccess, 
    retry: ViaRetry(maxAttempts: 3),
  ),
);
```

### 🛑 Request Cancellation & cURL
Easily cancel requests or convert them to cURL commands for debugging.

```dart
final cancelToken = CancelToken();
via.get('/data', cancelToken: cancelToken);
cancelToken.cancel();

// cURL debugging
print(result.request.toCurl());
```

### 💎 Custom Result Types
Extend `ViaResult` and use a pipeline to create your own type-safe response models.

```dart
class MyResponse extends ViaResult {
  MyResponse({required super.request, required super.response});
  bool get hasError => response.body.contains('error');
}

final via = Via<MyResponse>(
  executor: ViaExecutor(
    pipelines: [MyResponsePipeline()], // Transforms ViaResult -> MyResponse
  ),
);
```

---

## ⚖️ License
This project is licensed under the MIT License.

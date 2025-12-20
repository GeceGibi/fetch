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
  // 1. Initialize Via
  final via = Via(base: Uri.parse('https://api.example.com'));

  // 2. Simple GET request
  final result = await via.get('/users/1');
  
  // 3. Type-safe JSON parsing
  final user = await result.asMap<String, dynamic>();
  print('User Name: ${user['name']}');
}
```

---

## 🔥 Key Features

### 🛠️ Pipeline Architecture
Use pipelines for logging, authentication, and more.

```dart
final via = Via(
  base: Uri.parse('https://api.example.com'),
  executor: ViaExecutor(
    pipelines: [
      ViaLoggerPipeline(),
      ViaAuthPipeline(getToken: () => 'YOUR_TOKEN'),
    ],
  ),
);
```

### 🛡️ Retry Logic
Automatic retry on network failures. By default, any status code outside the 200-299 range is treated as an error, triggering the retry mechanism. You can customize this behavior using `errorIf`.

```dart
final via = Via(
  executor: ViaExecutor(
    // Custom logic: Treat 404 as a success, but others as errors
    errorIf: (result) => result.response.statusCode != 404 && !result.isSuccess,
    retry: ViaRetry(
      maxAttempts: 3,
      retryIf: (error, attempt) => true,
    ),
  ),
);
```

### 🛑 Request Cancellation
Easily cancel ongoing requests.

```dart
final cancelToken = CancelToken();
via.get('/large-data', cancelToken: cancelToken);

// Cancel later
cancelToken.cancel();
```

### 💎 Custom Result Types
Extend `ViaResult` to create your own type-safe response models and manipulate them in pipelines.

```dart
class MyResponse extends ViaResult {
  MyResponse({required super.request, required super.response});
  bool get hasError => response.body.contains('error');
}

class MyPipeline extends ViaPipeline<MyResponse> {
  @override
  MyResponse onResult(MyResponse result) {
    // Access custom properties in pipelines
    if (result.hasError) print('Error detected!');
    return result;
  }
}

// Initialize with your custom type
final via = Via<MyResponse>(executor: ViaExecutor(pipelines: [MyPipeline()]));
```

---

## ⚖️ License
This project is licensed under the MIT License.

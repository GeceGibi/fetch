# 🛣️ Via

**A modern, platform-agnostic, type-safe HTTP & WebSocket client for Dart & Flutter.**

Via is a lightweight yet powerful networking engine designed for simplicity, performance, and flexibility. It is built to be completely independent of Flutter or specific platforms, making it ideal for mobile, web, desktop, and server-side Dart applications.

---

## 🚀 Key Highlights

- **Pure Dart:** Zero Flutter dependency (works in CLI, Server-side, and Flutter).
- **Pipeline Architecture:** Highly extensible request/response lifecycle.
- **Auto-Mapping:** Built-in support for mapping JSON directly to your models.
- **Memory Efficient:** Native support for streaming both requests and responses.
- **Isolate Ready:** Built-in support for running heavy parsing/networking in background isolates.
- **Resilient:** Automated retry logic with customizable conditions.
- **Debugging:** Integrated cURL command generation and detailed logging.

---

## 📦 Installation

Add `via` to your `pubspec.yaml`:

```yaml
dependencies:
  via: ^1.4.3
```

---

## 🛠️ Usage Examples

### 1. Simple JSON GET & Auto-Mapping
Forget manual `jsonDecode` and casting. Use `to<T>` for objects or `toListOf<T>` for lists.

```dart
final via = Via(base: Uri.parse('https://api.example.com'));

// Map to a single model
final result = await via.get('/users/1');
final user = await result.to(User.fromJson);

// Map to a list of models
final listResult = await via.get('/users');
final users = await listResult.toListOf(User.fromJson);
```

### 2. Memory-Efficient File Upload (Streaming)
Instead of loading a 1GB file into RAM, stream it directly from the disk.

```dart
final file = File('large_movie.mp4');

final result = await via.post(
  '/upload',
  body: file.openRead(), // Stream<List<int>>
);
```

### 3. Real-time Response Streaming
Process large downloads or event streams as they arrive using the dedicated `stream()` method, which returns a `Future<ViaResultStream>`.

```dart
// .stream() returns Future<ViaResultStream>
final result = await via.stream('/large-video.mp4');

print('Status: ${result.statusCode}');

result.stream.listen((chunk) {
  print('Received ${chunk.length} bytes');
});
```

### 4. WebSocket with Auto-Reconnect
Lightweight WebSocket wrapper with pipeline support and automatic reconnection.

```dart
final socket = await via.socket(
  '/ws', 
  autoReconnect: true,
  reconnectDelay: Duration(seconds: 5),
);

socket.stream.listen((message) => print('Received: $message'));
socket.send({'type': 'ping'});
```

---

## 🔥 Advanced Features

### 🛠️ Pipeline Architecture
Pipelines are the core of Via. They allow you to intercept, modify, or even skip requests and responses.

- **`ViaLoggerPipeline`**: Automatically tracks request history and prints cURL commands.
- **`ViaCachePipeline`**: Smart in-memory caching with FIFO management.
- **`ViaAuthPipeline`**: (Custom) Inject tokens or handle 401 Unauthorized globally.

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

### 🛡️ Resilience & Retries
Configure how your application handles failures. Use `errorIf` to treat specific status codes or response patterns as errors that trigger a retry.

```dart
final via = Via(
  executor: ViaExecutor(
    retry: ViaRetry(
      maxAttempts: 3,
      delay: Duration(seconds: 2),
    ),
    errorIf: (result) => result.statusCode == 503, // Retry only on Service Unavailable
  ),
);
```

### 🛑 Request Cancellation
Stop ongoing requests instantly using a `CancelToken`.

```dart
final cancelToken = CancelToken();
via.get('/huge-data', cancelToken: cancelToken);

// Later...
cancelToken.cancel();
```

---

## 🏗️ Design Philosophy

Via is designed to be **lightweight** and **transparent**. It doesn't hide the underlying `http` package but enhances it with a structured execution flow. 

1. **Request Phase:** Pipelines can modify headers, base URL, or even return a cached response to skip the network call.
2. **Execution Phase:** The request is executed, optionally in a background Isolate to keep your UI smooth.
3. **Response Phase:** Pipelines can validate the response, log it, or transform it before it reaches your business logic.

---

## ⚖️ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

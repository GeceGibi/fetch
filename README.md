# Via

**A modern, platform-agnostic, type-safe HTTP client for Dart & Flutter.**

Via is a lightweight yet powerful networking engine designed for simplicity, performance, and flexibility. It is built to be completely independent of Flutter or specific platforms, making it ideal for mobile, web, desktop, and server-side Dart applications.

---

## Key Highlights

- **Pure Dart:** Zero Flutter dependency (works in CLI, Server-side, and Flutter).
- **Pipeline Architecture:** Highly extensible request/response lifecycle.
- **Auto-Mapping:** Built-in support for mapping JSON directly to your models.
- **Memory Efficient:** Native support for streaming both requests and responses.
- **Isolate Ready:** Built-in support for running heavy parsing/networking in background isolates.
- **Resilient:** Automated retry logic with customizable conditions.
- **Debugging:** Integrated cURL command generation and detailed logging.

---

## Installation

Add `via` to your `pubspec.yaml`:

```yaml
dependencies:
  via: ^1.6.1
```

---

## Usage Examples

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

---

## Advanced Features

### Pipeline Architecture
Pipelines are the core of Via. They allow you to intercept, modify, or even skip requests and responses.

- **`ViaLoggerPipeline`**: Automatically tracks request history and prints cURL commands.
- **`ViaCachePipeline`**: Smart in-memory caching with FIFO management.
- **`ViaAuthPipeline`**: (Custom) Inject tokens or handle 401 Unauthorized globally.

```dart
final via = Via(
  pipelines: [
    ViaLoggerPipeline(),
    ViaCachePipeline(duration: Duration(minutes: 5), maxEntries: 100),
  ],
);
```

### Resilience & Retries
Configure how your application handles failures. Custom retry logic can be defined in the `ViaRetry` object.

```dart
final via = Via(
  retry: ViaRetry(
    maxRetries: 3,
    retryDelay: Duration(seconds: 2),
    retryIf: (error, attempt) => error.type == .network,
  ),
);
```

> **Note:** Retry does not work with streaming request bodies (`Stream<List<int>>`). Since streams can only be consumed once, failed requests with stream bodies cannot be retried.

### Request Cancellation
Stop ongoing requests instantly using a `CancelToken`.

```dart
final cancelToken = CancelToken();
via.get('/huge-data', cancelToken: cancelToken);

// Later...
cancelToken.cancel();
```

### Isolate Compliance
Via is designed to be fully compatible with Dart Isolates. Since some objects like `StreamedResponse` or `ByteStream` cannot be sent between isolates, all core classes (`ViaRequest`, `ViaResult`, `ViaResultStream`) provide a `.toSafeVersion()` method.

- **`ViaLoggerPipeline`** automatically uses this to ensure that even streaming results stored in the `logs` history do not cause "illegal argument in isolate message" errors when the client is used across isolate boundaries.
- This ensures metadata (status codes, headers, cURL commands) is preserved while stripping unsendable active streams.

---

## Design Philosophy

Via is designed to be **lightweight** and **transparent**. It doesn't hide the underlying `http` package but enhances it with a structured execution flow. 

1. **Request Phase:** Pipelines can modify headers, base URL, or even return a cached response to skip the network call.
2. **Execution Phase:** The request is executed, optionally in a background Isolate to keep your UI smooth.
3. **Response Phase:** Pipelines can validate the response, log it, or transform it before it reaches your business logic.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

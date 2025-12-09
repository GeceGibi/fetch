## 3.2.1 - 2025-12-09

### Added
- `headers` parameter to `retry()` method for overriding request headers during retry
- `headers` parameter to `retryWith()` method for overriding request headers during retry

### Examples
```dart
// Retry with new headers
await response.retry(headers: {'Authorization': 'Bearer new-token'});

// Retry with modified payload and new headers
await response.retryWith(newPayload, headers: {'Authorization': 'Bearer new-token'});
```

## 3.2.0 - 2025-12-08

### Added
- `CancelToken` class for request cancellation
- `CancelledException` thrown when requests are cancelled
- `cancelToken` parameter to all HTTP methods (get, post, put, delete, patch, head)

### Changed
- `FetchHelpers.mapStringy()` code optimization
- HTTP client now properly closes after each request

### Examples
```dart
final token = CancelToken();
fetch.get('/endpoint', cancelToken: token);
token.cancel(); // Cancel the request
```

## 3.1.0+10

* Previous version

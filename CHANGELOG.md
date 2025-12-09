## 3.3.0 - 2025-12-09

### Changed
- **BREAKING**: `retry()` method now accepts an optional callback function for payload modification
- **BREAKING**: `retryWith()` method removed, use `retry()` callback instead

### Examples
```dart
// Retry with original payload
await response.retry();

// Retry with modified payload
await response.retry((payload) {
  return payload.copyWith(
    headers: {'Authorization': 'Bearer new-token'},
  );
});

// Modify multiple fields
await response.retry((payload) {
  return payload.copyWith(
    headers: {'Authorization': 'Bearer new-token'},
    body: newBody,
  );
});
```

## 3.2.2 - 2025-12-09

### Changed
- Code organization: `FetchPayload` moved to separate file for better maintainability

## 3.2.1 - 2025-12-09

### Added
- `headers` parameter to `retry()` method for overriding request headers during retry
- `headers` parameter to `retryWith()` method for overriding request headers during retry

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

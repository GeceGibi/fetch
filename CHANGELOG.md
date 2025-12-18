## 4.1.0 - 2025-12-18

### Executor Pattern Implementation
- **NEW**: Added `RequestExecutor` abstraction for platform-specific execution strategies
- **NEW**: `DefaultExecutor` - runs requests in main isolate (default)
- **NEW**: `IsolateExecutor` - runs requests and transforms in separate isolate for CPU-intensive operations
- **ENHANCEMENT**: Transform function now executes within executor context
- **BENEFIT**: Prevents UI blocking during heavy JSON parsing or data transformations
- **BENEFIT**: Platform-aware execution (isolate on mobile/desktop, direct on web)

### Usage
```dart
// Before (4.x) - using override
final fetch = Fetch(
  override: (payload, method) async {
    // Custom request handling
    return await compute(() => method(payload));
  },
);

// After (5.x) - using executor
final fetch = Fetch(
  executor: RequestExecutor.isolate(), // or RequestExecutor.direct()
  transform: (response) {
    // Heavy parsing in isolate
    return jsonDecode(response.response.body);
  },
);

// Default executor (main isolate) - no need to specify
final simpleFetch = Fetch(
  transform: (response) => response.response.body,
);
```

## 4.0.0 - 2025-12-18

### Major Refactor
- **BREAKING**: Converted from `part`/`part of` to modular architecture with package imports
- **BREAKING**: Removed throttling feature, replaced with debouncing
- **NEW**: Added retry mechanism with exponential backoff
- **NEW**: Added interceptor system (LogInterceptor, AuthInterceptor, RetryInterceptor)
- **NEW**: Added FetchException with detailed error types
- **NEW**: Added global error handler (onError callback)
- **NEW**: Reorganized project structure:
  - `/lib/src/core/` - Core HTTP functionality
  - `/lib/src/features/` - Feature modules (cache, cancel, debounce, interceptor, retry)
  - `/lib/src/utils/` - Utilities (exception)
  - `/example/` - Standalone example package

### Features
- **Debounce**: Prevent duplicate rapid requests
- **Retry**: Automatic retry with configurable attempts and delays
- **Interceptors**: Request/response/error middleware
- **Exception Handling**: 8 detailed exception types with helper methods
- **Global Error Handler**: Centralized error management

### Breaking Changes
- ThrottleOptions removed, use DebounceOptions instead
- CancelledException removed, use FetchException with type=cancelled
- All files now use package imports instead of part/part of
- Private APIs (_addCallback, _removeCallback) now public (addCallback, removeCallback)

### Migration Guide
```dart
// Before (3.x)
final fetch = Fetch(
  throttleOptions: ThrottleOptions(duration: Duration(seconds: 2)),
);

// After (4.x)
final fetch = Fetch(
  debounceOptions: DebounceOptions(duration: Duration(seconds: 1)),
  retryOptions: RetryOptions(maxAttempts: 3),
  interceptors: [LogInterceptor(), AuthInterceptor(...)],
  onError: (error, stackTrace) => handleError(error),
);

// Exception handling
try {
  await fetch.get('/api');
} on FetchException catch (e) {
  if (e.isTimeout) { /* handle timeout */ }
  if (e.isServerError) { /* handle 5xx */ }
}
```

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

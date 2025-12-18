## 8.3.0 - 2025-12-18

### Improvements

- **IMPROVED**: `RetryExecutor.retryIf` now supports async callbacks (`FutureOr<bool>`)
  - Enables token refresh before retry on 401 errors
  - User-transparent authentication renewal

### Example

```dart
RetryExecutor(
  executor: const DefaultExecutor(),
  maxAttempts: 2,
  retryIf: (error) async {
    if (error.statusCode == 401) {
      await refreshToken(); // Refresh token silently
      return true; // Retry with new token
    }
    return false;
  },
)
```

## 8.2.0 - 2025-12-18

### Breaking Changes

- **BREAKING**: Removed `uri` and `method` parameters from `FetchException`
  - Now only accessible via `payload.uri` and `payload.method`
  - Simplifies API since payload already contains all request info

### Migration Guide

```dart
// Before
FetchException(
  uri: uri,
  method: 'GET',
  type: FetchExceptionType.http,
);

// After
FetchException(
  payload: payload,
  type: FetchExceptionType.http,
);

// Access via getters (unchanged)
error.uri     // returns payload?.uri
error.method  // returns payload?.method
```

## 8.1.0 - 2025-12-18

### Breaking Changes

- **BREAKING**: Removed `Interceptor.onError` method
  - Error handling is now done via `Fetch.onError` callback only
  - Interceptors no longer receive error notifications

- **BREAKING**: Simplified `FetchExceptionType` enum
  - `connectionError`, `timeout`, `unknown`, `parseError` → `network`
  - `httpError` → `http`
  - New enum values: `cancelled`, `debounced`, `throttled`, `network`, `http`

### Improvements

- **NEW**: `CacheInterceptor` moved to separate file (`lib/src/features/cache.dart`)
- Cleaner separation of concerns

### Migration Guide

```dart
// Before
error.type == FetchExceptionType.httpError
error.type == FetchExceptionType.connectionError
error.type == FetchExceptionType.timeout
error.type == FetchExceptionType.unknown

// After
error.type == FetchExceptionType.http
error.type == FetchExceptionType.network  // covers connection, timeout, unknown
```

## 8.0.0 - 2025-12-18

### Breaking Changes

- **BREAKING**: Simplified `FetchException` structure
  - Changed `uri` parameter to `payload` (FetchPayload) - now includes full request context (uri, method, headers, body)
  - `uri` is now a getter that returns `payload.uri`
  - Removed: `message` parameter (now computed from `error`), `statusCode`, `data`
  - Required parameters: `payload`, `type`
  - Optional parameters: `error`, `stackTrace`
  - Removed factory constructors: `.timeout()`, `.connectionError()`, `.httpError()`, `.parseError()`
  - Removed helper getters: `isHttpError`, `isTimeout`, `isConnectionError`, `isClientError`, `isServerError`
  - Use `error.type == FetchExceptionType.xxx` instead of helper getters
  - `toString()` now includes method, headers, and body for better debugging

### Migration Guide

```dart
// Before
throw FetchException(
  message: 'Request cancelled',
  type: FetchExceptionType.cancelled,
  uri: uri,
);

if (error.isServerError) { ... }

// After
throw FetchException(
  payload: payload,
  type: FetchExceptionType.cancelled,
);

if (error.type == FetchExceptionType.httpError) { ... }

// Access request details
print(error.payload.method);  // GET, POST, etc.
print(error.payload.headers); // Request headers
print(error.payload.body);    // Request body
```

## 7.1.0 - 2025-12-18

### New Features
- **NEW**: `ThrottleInterceptor` - Limits request rate by executing only the first request within a time window
  - Unlike debounce (which executes last), throttle executes the first request and rejects subsequent requests until the duration expires
  - Usage: `interceptors: [ThrottleInterceptor(duration: Duration(seconds: 1))]`
- **NEW**: `FetchExceptionType.throttled` - Exception type for throttled requests

### Example
```dart
// Throttle - only first request executes
final fetch = Fetch<FetchResponse>(
  interceptors: [
    ThrottleInterceptor(duration: Duration(seconds: 1)),
  ],
);

// First request executes, others are throttled
for (var i = 0; i < 5; i++) {
  fetch.get('/api/data');
  await Future.delayed(Duration(milliseconds: 100));
}
```

## 7.0.0 - 2025-12-18

### Breaking Changes - Complete Interceptor Pipeline Architecture
- **REMOVED**: `debounceOptions` parameter from `Fetch` constructor and HTTP methods
  - Use `DebounceInterceptor` instead: `interceptors: [DebounceInterceptor(duration: Duration(seconds: 1))]`
- **REMOVED**: `cacheOptions` parameter from `Fetch` constructor and HTTP methods  
  - Use `CacheInterceptor` instead: `interceptors: [CacheInterceptor(duration: Duration(minutes: 5))]`
- **REMOVED**: `CacheFactory` mixin from `Fetch` class
- **REMOVED**: `clearCache()`, `clearDebounce()` methods from `Fetch` class
  - Access these methods directly on interceptor instances
- **REMOVED**: `ErrorInterceptor` class
- **ADDED**: `onError` callback parameter to `Fetch` constructor for global error handling
- **CHANGED**: Interceptor `onRequest` now returns `InterceptorResult` (either `ContinueRequest` or `SkipRequest`)
  - This allows interceptors like `CacheInterceptor` to skip the actual HTTP request
- **NEW**: `DebounceInterceptor` - handles request debouncing
- **NEW**: `CacheInterceptor` - handles response caching with skip-request capability
- **BENEFIT**: Clean pipeline architecture - request flows through interceptor chain, any interceptor can modify, skip, or fail

### Migration Guide
```dart
// Debounce: Before (6.x)
final fetch = Fetch<FetchResponse>(
  debounceOptions: DebounceOptions(duration: Duration(seconds: 1)),
);

// Debounce: After (7.x)
final fetch = Fetch<FetchResponse>(
  interceptors: [
    DebounceInterceptor(duration: Duration(seconds: 1)),
  ],
);

// Cache: Before (6.x)
final fetch = Fetch<FetchResponse>(
  cacheOptions: CacheOptions(duration: Duration(minutes: 5)),
);

// Cache: After (7.x)
final fetch = Fetch<FetchResponse>(
  interceptors: [
    CacheInterceptor(duration: Duration(minutes: 5)),
  ],
);

// Error Handling: Before (6.x)
final fetch = Fetch<FetchResponse>(
  interceptors: [ErrorInterceptor(onErrorCallback: (e) => print(e))],
);

// Error Handling: After (7.x)
final fetch = Fetch<FetchResponse>(
  onError: (error) => print(error),
);

// Combine multiple interceptors - they form a pipeline
final fetch = Fetch<FetchResponse>(
  interceptors: [
    LogInterceptor(),
    CacheInterceptor(duration: Duration(minutes: 5)),
    DebounceInterceptor(duration: Duration(milliseconds: 500)),
    AuthInterceptor(getToken: () => getToken()),
  ],
  onError: (error) => logError(error),
);
```

## 6.0.0 - 2025-12-18

### Breaking Changes - Moved to Interceptor/Executor Pattern
- **REMOVED**: `retryOptions` parameter from `Fetch` constructor and all HTTP methods
  - Use `RetryExecutor` wrapper instead: `executor: RetryExecutor(executor: DefaultExecutor(), maxAttempts: 3)`
- **REMOVED**: `enableLogs` parameter from `Fetch` constructor and all HTTP methods
  - Use `LogInterceptor` instead: `interceptors: [LogInterceptor()]`
- **REMOVED**: `onError` callback parameter from `Fetch` constructor
  - Use `ErrorInterceptor` instead: `interceptors: [ErrorInterceptor(onErrorCallback: (e) => print(e))]`
- **REMOVED**: `FetchLog` class and `fetchLogs` list
  - Logging is now handled by `LogInterceptor`
- **REMOVED**: `lib/src/core/logger.dart` file
- **NEW**: `RetryExecutor` - wraps any executor with retry logic
- **NEW**: `ErrorInterceptor` - simple error callback interceptor
- **BENEFIT**: Cleaner API, better separation of concerns, composable functionality

### Migration Guide
```dart
// Retry: Before (5.x)
final fetch = Fetch<FetchResponse>(
  retryOptions: RetryOptions(maxAttempts: 3),
);

// Retry: After (6.x)
final fetch = Fetch<FetchResponse>(
  executor: RetryExecutor(
    executor: const DefaultExecutor(),
    maxAttempts: 3,
    retryDelay: Duration(seconds: 1),
  ),
);

// Logging: Before (5.x)
final fetch = Fetch<FetchResponse>(
  enableLogs: true,
);

// Logging: After (6.x)
final fetch = Fetch<FetchResponse>(
  interceptors: [LogInterceptor()],
);

// Error Handling: Before (5.x)
final fetch = Fetch<FetchResponse>(
  onError: (error, stackTrace) => print('Error: $error'),
);

// Error Handling: After (6.x)
final fetch = Fetch<FetchResponse>(
  interceptors: [
    ErrorInterceptor(onErrorCallback: (error) => print('Error: $error')),
  ],
);

// Combine retry + isolate + logging
final fetch = Fetch<FetchResponse>(
  executor: RetryExecutor(
    executor: const IsolateExecutor(),
    maxAttempts: 3,
  ),
  interceptors: [
    LogInterceptor(),
    ErrorInterceptor(onErrorCallback: (e) => print(e)),
  ],
);
```

## 5.0.0 - 2025-12-18

### Breaking Changes
- **SIMPLIFIED**: `transform` moved back to `Fetch` constructor
- **SIMPLIFIED**: `RequestExecutor` no longer handles transforms
- **CHANGED**: `IsolateExecutor` now uses `Isolate.run` instead of `Isolate.spawn`
- **REMOVED**: Transform parameters from executor factories
- **BENEFIT**: Simpler API, cleaner separation of concerns

### Migration Guide
```dart
// Before (4.x)
final fetch = Fetch<Map<String, dynamic>>(
  executor: RequestExecutor.direct(
    transform: (response) => jsonDecode(response.response.body),
  ),
);

// After (5.x)
final fetch = Fetch<Map<String, dynamic>>(
  transform: (response) => jsonDecode(response.response.body),
  executor: const RequestExecutor.direct(), // optional
);

// Isolate executor - simpler with Isolate.run
final fetchIsolate = Fetch<Map<String, dynamic>>(
  executor: const RequestExecutor.isolate(),
  transform: (response) => jsonDecode(response.response.body),
);
```

## 4.4.0 - 2025-12-18

### Improvements
- **UNIFIED**: All transform functions now use `TransformFunction<dynamic>`
- **REMOVED**: `IsolateTransformFunction` typedef (replaced with `TransformFunction`)
- **IMPROVED**: Consistent type usage across all executors
- **BENEFIT**: Cleaner, more maintainable codebase

## 4.3.0 - 2025-12-18

### Breaking Changes
- **REMOVED**: `transform` parameter from `Fetch` constructor
- **MOVED**: Transform logic is now part of `RequestExecutor`
- **NEW**: `RequestExecutor.direct()` now accepts optional `transform` parameter
- **BENEFIT**: Cleaner separation of concerns - executors handle their own transforms

### Migration Guide
```dart
// Before (4.2.x)
final fetch = Fetch<Map<String, dynamic>>(
  transform: (response) => jsonDecode(response.response.body),
);

// After (4.3.x)
final fetch = Fetch<Map<String, dynamic>>(
  executor: RequestExecutor.direct(
    transform: (response) => jsonDecode(response.response.body),
  ),
);
```

## 4.2.0 - 2025-12-18

### Improvements
- **SIMPLIFIED**: IsolateExecutor now has cleaner logic
- **REMOVED**: Auto JSON decode complexity - user decides transform behavior
- **IMPROVED**: Transform only runs if `isolateTransform` is provided
- **BENEFIT**: Simpler, more predictable executor behavior

## 4.1.0 - 2025-12-18

### Executor Pattern Implementation
- **NEW**: Added `RequestExecutor` abstraction for platform-specific execution strategies
- **NEW**: `DefaultExecutor` - runs requests in main isolate (default)
- **NEW**: `IsolateExecutor` - runs HTTP requests in separate isolate, transforms in main isolate
- **BENEFIT**: Prevents UI blocking during network requests
- **BENEFIT**: Platform-aware execution (isolate on mobile/desktop, direct on web)
- **NOTE**: Transform functions run in main isolate to avoid closure serialization issues

### Usage
```dart
// Before (4.x) - using override
final fetch = Fetch(
  override: (payload, method) async {
    // Custom request handling
    return await compute(() => method(payload));
  },
);

// After (4.1.x) - using executor
final fetch = Fetch(
  executor: RequestExecutor.isolate(), // HTTP request in isolate
  transform: (response) {
    // Transform runs in main isolate
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

# Changelog

All notable changes to this project will be documented in this file.

## [1.6.0]

### Changed
- **BREAKING**: Renamed `maxAttempts` to `maxRetries` in `ViaRetry`. Now `0` means no retries (clearer semantics).
- **BREAKING**: Renamed `onStream` to `onResultStream` in `ViaPipeline` for consistency with `onResult`.

### Fixed
- **Debounce Cleanup**: Fixed potential memory leak in `ViaDebouncePipeline` when requests fail or throw exceptions.

### Docs
- Added warning about retry not working with streaming request bodies (`Stream<List<int>>`).

## [1.5.5]

### Changed
- **Pipeline Architecture**: Refactored `ViaPipeline` for better type safety and clarity.
    - `onResult` now specifically handles `ViaResult` (buffered responses).
    - `onStream` now receives the full `ViaResultStream` object instead of raw stream chunks, allowing access to response metadata (headers, status code) during streaming.
- **Enhanced Streaming**: Added `ViaResultStream.copyWith` to allow pipelines to transform response streams while preserving metadata.
- **Improved Validation**: `ViaResponseValidatorPipeline` now supports validation of both buffered and streaming responses.

## [1.5.4]

### Fixed
- **Map Body Casting**: Fixed an issue where `Map` payloads with non-string values (like `int` or `bool`) would cause a type cast error. They are now automatically converted to strings for form-data requests.

### Changed
- **Modernized Syntax**: Fully adopted Modern Dart enum member access (e.g., `.network` instead of `ViaError.network`).
- **Simplified Examples**: Consolidated multiple example files into a single, clean `example/main.dart`.
- **Unit Tests**: Added a comprehensive suite of unit tests with real network request validation.

## [1.5.3]

### Fixed
- **Pipeline Error Handling**: Fixed an issue where `onError` was not being called on pipelines when a request failed.
- **Logger Stream Support**: Added stream error tracking to `ViaLoggerPipeline` via `onStream` interception.

## [1.5.2]

### Changed
- **Architecture Refinement**: Simplified internal request handling by returning `ViaBaseResult` from `worker` and handling type casting in `ViaMethods`. This provides better flexibility for custom result types (like `SotyResult`) used with pipelines.

## [1.5.1]

### Fixed
- **Type Safety**: Fixed a critical `type 'ViaResult' is not a subtype of type 'R' in type cast` error in `ViaMethods`. Both `Via.worker` and `ViaMethods._request` are now generic to correctly handle custom result types.

## [1.5.0]

### Changed
- **Simplified API**: Removed `ViaExecutor` class. All execution logic (pipelines, retry, runner) has been moved directly into the `Via` class for a cleaner and more intuitive API.
- **Truly Pure Dart**: Removed the `flutter` SDK dependency. The library is now a pure Dart package, compatible with CLI, Server-side, and Flutter.
- **HTTP Focus**: Removed internal WebSocket support to keep the library lightweight and focused on HTTP.
- **Auto-mapping Support**: Added `to<T>` and `toListOf<T>` methods to `ViaResult` for seamless JSON-to-Model conversion.
- **Stream Body Support**: Enhanced `Via` to support `Stream<List<int>>` as a request body.
- **Dedicated Streaming API**: Introduced `via.stream()` method which returns `Future<ViaResultStream>`. This allows accessing status codes and headers before consuming the response stream.
- **Internal Refactoring**: Organized source files into a flatter, more logical structure.

### Fixed
- **Isolate Stability**: Explicitly detaching the request object from the response before returning from an isolate. This prevents "Illegal argument in isolate message" errors caused by unsendable `ByteStream` references in `MultipartRequest`.
- **Auto Isolate Bypass**: Added automatic Isolate bypass for requests containing `Stream` bodies or `CancelToken`s.

### Changed
- **API Simplification**: Removed `ViaCall` wrapper. Standard HTTP methods now return `Future<ViaResult>` directly.
- **Dedicated Streaming API**: Introduced `via.stream()` method which returns `Future<ViaResultStream>`. This allows accessing status codes and headers before consuming the response stream.

## [1.4.1]

### Added
- **Fluent API with ViaCall**: Introduced `ViaCall` which implements `Future`, allowing direct `await via.get()` while providing a `.stream` getter for byte streaming.
- **Streaming Response Support**: Added real-time byte streaming with `.stream` getter on any request.
- **Improved Result Buffering**: `ViaResult` now handles lazy buffering, allowing both streaming and future-based body access on the same result.
- **Pipeline onStream Support**: Added `onStream` hook to `ViaPipeline` for intercepting or transforming data chunks in real-time without blocking the stream.
- **New Example**: Added `example/stream_response.dart` to demonstrate the new streaming capabilities.

### Changed
- **Modern Dart Syntax**: Adopted modern Dart enum member access (e.g., `.get` instead of `ViaMethod.get`).
- **Isolate Safety**: Refactored `ViaResult` to be isolate-friendly by lazily initializing non-sendable fields like `Completer`.
- **API Cleanup**: Removed redundant `isStream` flags and explicit `via.stream()` methods in favor of the more intuitive `.stream` getter on any call.

## [1.3.0]

### Added
- **Multipart Upload Support**: Dedicated `via.multipart()` method for form-data and file uploads.
- **WebSocket Support**: Introduced `ViaSocket` for lightweight and flexible WebSocket connections.
- **WebSocket Pipelines**: Added `ViaSocketPipeline` for intercepting lifecycle events.
- **WebSocket Auto-Reconnect**: Support for `autoReconnect` and `reconnectDelay`.
- **Smart URI Conversion**: Automatic `http`/`https` to `ws`/`wss` conversion.
- **Examples**: Added `multipart_example.dart`.

### Changed
- **API Simplification**: Shorthand methods (`post`, `put`, `patch`, `delete`) now only handle standard bodies. All file uploads must use `via.multipart()`.
- **Internal Refactoring**: Moved HTTP methods to `ViaMethods` mixin and organized pipelines into `src/features/pipelines/`.
- Removed `part`/`part of` structure in favor of standard imports.

## [1.2.4]

### Changed
- Refactored HTTP methods to use the `ViaMethod` enum for better type safety and consistency.
- Updated `ViaRequest.toCurl()` and `ViaRequest.toString()` to correctly use enum values.
- Internal cleanup of method parameter types across the library.

## [1.2.3]

### Changed
- Internal cleanup: Removed redundant generic type parameters from `ViaExecutor` and `ViaRetry`.
- Simplified internal execution flow by centralizing type casting in the `Via` class.
- Improved code maintainability by reducing generic boilerplate in core feature classes.
- Updated all examples to support sequential execution via `Future<void> main()`.
- Improved `example/main.dart` to act as a comprehensive test runner for all features.
- Enhanced `example/pipeline.dart` with a custom logger for better visibility.

## [1.2.2]

### Fixed
- Further improved `toCurl` character escaping by using single quotes for headers and URL to prevent shell interpretation issues.
- Fixed `toJson` in `ViaResult` to correctly handle null-aware response properties.
- Added `response` object to `ViaException` in `ViaResponseValidatorPipeline` for better debugging.

## [1.2.1]

### Fixed
- Fixed `toJson` and `toCurl` implementations in `ViaRequest`.
- Improved cURL command generation with better character escaping for terminal compatibility.
- Fixed `ViaException` JSON serialization by correcting null-aware syntax.
- Adopted modern Dart null-aware map entries syntax (`?variable`) for cleaner metadata.

## [1.2.0]

### Changed
- Refactored `ViaPipeline` to be non-generic for better flexibility and simplicity.
- Removed generic requirements from all built-in pipelines (`ViaLoggerPipeline`, `ViaCachePipeline`, etc.).
- Simplified custom result transformation by removing `covariant` complexity in favor of standard inheritance.

## [1.1.0]

## [1.0.0]

### Added
- Initial release of the Via HTTP engine.
- `Via` class for high-level HTTP operations.
- `ViaExecutor` with support for `ViaPipeline` architecture.
- Built-in resilience with `ViaRetry` (automatic retries).
- Request cancellation support via `CancelToken`.
- Type-safe JSON parsing helpers (`asMap`, `asList`).
- Memory-managed `ViaCachePipeline` (FIFO with `maxEntries`).
- Advanced pipelines: `ViaLoggerPipeline` (with cURL support), `ViaDebouncePipeline`, `ViaThrottlePipeline`, and `ViaResponseValidatorPipeline`.
- Connection pooling support with shared `http.Client`.
- Isolate-based execution support for background processing.
- `errorIf` validation in `ViaExecutor` to treat HTTP responses as errors (defaults to non-2xx).

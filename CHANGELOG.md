# Changelog

All notable changes to this project will be documented in this file.

## [1.4.1]

### Added
- **Auto-mapping Support**: Added `to<T>` and `toListOf<T>` methods to `ViaResult` for seamless JSON-to-Model conversion.
- **Stream Body Support**: Enhanced `Via` to support `Stream<List<int>>` as a request body, enabling memory-efficient large file uploads.

## [1.4.0]

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
- **Examples**: Added `multipart_example.dart`, `socket_example.dart`, and `socket_reconnect_test.dart`.

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

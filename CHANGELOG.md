# Changelog

All notable changes to this project will be documented in this file.

## [1.2.2] - 2025-12-20

### Fixed
- Further improved `toCurl` character escaping by using single quotes for headers and URL to prevent shell interpretation issues.
- Fixed `toJson` in `ViaResult` to correctly handle null-aware response properties.
- Added `response` object to `ViaException` in `ViaResponseValidatorPipeline` for better debugging.

## [1.2.1] - 2025-12-20

### Fixed
- Fixed `toJson` and `toCurl` implementations in `ViaRequest`.
- Improved cURL command generation with better character escaping for terminal compatibility.
- Fixed `ViaException` JSON serialization by correcting null-aware syntax.
- Adopted modern Dart null-aware map entries syntax (`?variable`) for cleaner metadata.

## [1.2.0] - 2025-12-20

### Changed
- Refactored `ViaPipeline` to be non-generic for better flexibility and simplicity.
- Removed generic requirements from all built-in pipelines (`ViaLoggerPipeline`, `ViaCachePipeline`, etc.).
- Simplified custom result transformation by removing `covariant` complexity in favor of standard inheritance.

## [1.1.0] - 2025-12-20

## [1.0.0] - 2025-12-20

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

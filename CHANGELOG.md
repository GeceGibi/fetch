# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2025-12-20

### Added
- Enhanced `ViaPipeline` result transformation with `covariant` support.
- Improved custom `ViaResult` subclasses support via pipeline-based type conversion.

### Changed
- `ViaPipeline.onResult` now accepts `covariant ViaResult` to allow type narrowing in custom pipelines.
- Internal execution flow now allows late casting to the generic result type `R`.

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

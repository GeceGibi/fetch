# Changelog

All notable changes to this project will be documented in this file.

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

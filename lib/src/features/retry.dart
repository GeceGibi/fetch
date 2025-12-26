import 'dart:async';

import 'package:via/src/core/result.dart';

/// Handles automatic request retries for failed operations.
///
/// Can be configured with a maximum number of attempts, a delay between
/// attempts, and custom logic to decide which errors should trigger a retry.
class ViaRetry {
  const ViaRetry({
    this.maxRetries = 0,
    this.retryIf = _defaultRetryIf,
    this.retryDelay = const Duration(seconds: 2),
  });

  /// Maximum number of retry attempts (0 = no retries, 1 = one retry, etc.)
  final int maxRetries;

  /// Logic to decide if an error should trigger a retry.
  final FutureOr<bool> Function(ViaException error, int attempt) retryIf;

  /// Delay between retry attempts.
  final Duration retryDelay;

  /// Executes the [action] and retries it if it fails according to [retryIf].
  Future<T> retry<T extends ViaBaseResult>(Future<T> Function() action) async {
    var attempt = 0;

    while (true) {
      attempt++;

      try {
        return await action();
      } on ViaException catch (error) {
        if (error.type == .cancelled) {
          rethrow;
        }

        final shouldRetry = await retryIf(error, attempt);

        if (attempt <= maxRetries && shouldRetry) {
          await Future<void>.delayed(retryDelay);
          continue;
        }

        rethrow;
      }
    }
  }

  static bool _defaultRetryIf(ViaException error, int attempt) {
    final ViaException(:type, :response) = error;

    return type == .network ||
        (response?.statusCode != null && response!.statusCode >= 500);
  }
}

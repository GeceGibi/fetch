import 'package:fetch/src/utils/exception.dart';

/// Retry options
class RetryOptions {
  const RetryOptions({
    this.maxAttempts = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.retryIf,
  });

  const RetryOptions.disabled() : this(maxAttempts: 1);

  /// Maximum number of attempts (1 = no retry)
  final int maxAttempts;

  /// Delay between retries
  final Duration retryDelay;

  /// Function to determine whether to retry
  final bool Function(FetchException error)? retryIf;

  bool get enabled => maxAttempts > 1;

  /// Default retry logic: server errors and network errors
  static bool defaultRetryIf(FetchException error) {
    return error.isServerError || error.isConnectionError || error.isTimeout;
  }
}

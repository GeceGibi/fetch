import 'dart:async';

import 'package:fetch/src/core/result.dart';

class FetchRetry {
  const FetchRetry({
    this.maxAttempts = 1,
    this.retryIf = _defaultRetryIf,
    this.retryDelay = const Duration(seconds: 2),
  });

  final int maxAttempts;
  final FutureOr<bool> Function(FetchException error, int attempt) retryIf;
  final Duration retryDelay;

  static bool _defaultRetryIf(FetchException error, int attempt) {
    return error.type == FetchError.network ||
        (error.response?.statusCode != null &&
            error.response!.statusCode >= 500);
  }

  Future<R> retry<R extends FetchResult>(Future<R> Function() action) async {
    var attempt = 0;

    while (true) {
      attempt++;

      try {
        return await action();
      } on FetchException catch (error) {
        final shouldRetry = await retryIf(error, attempt);

        if (attempt < maxAttempts && shouldRetry) {
          await Future<void>.delayed(retryDelay);

          continue;
        }

        // ignore: use_rethrow_when_possible
        throw error;
      }
    }
  }
}

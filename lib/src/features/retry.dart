import 'dart:async';

import 'package:fetch/src/core/result.dart';

class FetchRetry {
  const FetchRetry({
    this.maxAttempts = 1,
    this.retryIf = _defaultRetryIf,
    this.retryDelay = const Duration(seconds: 2),
  });

  final int maxAttempts;
  final FutureOr<bool> Function(FetchResultError error, int attempt) retryIf;
  final Duration retryDelay;

  static bool _defaultRetryIf(FetchResultError error, int attempt) {
    return error.type == FetchError.network ||
        (error.response?.statusCode != null &&
            error.response!.statusCode >= 500);
  }

  Future<R> retry<R extends FetchResult>(Future<R> Function() action) async {
    var attempt = 0;
    final stopWatch = Stopwatch();
    final elapsed = <Duration>[];

    while (true) {
      attempt++;
      stopWatch.start();

      try {
        final result = await action();
        result.elapsed.add(stopWatch.elapsed);
        return result;
      } on FetchResultError catch (error) {
        elapsed.add(stopWatch.elapsed);

        final shouldRetry = await retryIf(error, attempt);

        if (attempt < maxAttempts && shouldRetry) {
          await Future<void>.delayed(retryDelay);
          stopWatch.reset();
          continue;
        }

        error.elapsed.addAll(elapsed);

        // ignore: use_rethrow_when_possible
        throw error;
      } finally {
        stopWatch.stop();
      }
    }
  }
}

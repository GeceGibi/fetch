import 'dart:async';

import 'package:via/src/core/result.dart';

class ViaRetry {
  const ViaRetry({
    this.maxAttempts = 1,
    this.retryIf = _defaultRetryIf,
    this.retryDelay = const Duration(seconds: 2),
  });

  final int maxAttempts;
  final FutureOr<bool> Function(ViaException error, int attempt) retryIf;
  final Duration retryDelay;

  static bool _defaultRetryIf(ViaException error, int attempt) {
    return error.type == ViaError.network ||
        (error.response?.statusCode != null &&
            error.response!.statusCode >= 500);
  }

  Future<R> retry<R extends ViaResult>(Future<R> Function() action) async {
    var attempt = 0;

    while (true) {
      attempt++;

      try {
        return await action();
      } on ViaException catch (error) {
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

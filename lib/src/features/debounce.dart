import 'dart:async';

import 'package:fetch/src/utils/exception.dart';

/// Debounce options
class DebounceOptions {
  const DebounceOptions({required this.duration});
  const DebounceOptions.disabled() : duration = Duration.zero;

  final Duration duration;

  bool get enabled => duration > Duration.zero;
}

/// Simple debounce manager
class DebounceManager {
  final _timers = <String, Timer>{};
  final _completers = <String, Completer<dynamic>>{};

  Future<T> debounce<T>(
    String key,
    DebounceOptions options,
    Future<T> Function() fn,
  ) async {
    if (!options.enabled) {
      return fn();
    }

    // Cancel previous timer
    _timers[key]?.cancel();
    _completers[key]?.completeError(
      FetchException(
        message: 'Debounced',
        type: FetchExceptionType.debounced,
      ),
    );

    // Create new completer
    final completer = Completer<T>();
    _completers[key] = completer;

    // Start new timer
    _timers[key] = Timer(options.duration, () async {
      try {
        final result = await fn();
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      } finally {
        _timers.remove(key);
        _completers.remove(key);
      }
    });

    return completer.future;
  }

  void clear() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _completers.clear();
  }

  void clearKey(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
    _completers.remove(key);
  }
}

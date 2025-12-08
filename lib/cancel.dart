part of 'fetch.dart';

/// Token for canceling HTTP requests.
///
/// Create a token and pass it to request methods to enable cancellation.
///
/// Example:
/// ```dart
/// final cancelToken = CancelToken();
/// fetch.get('/users', cancelToken: cancelToken);
/// 
/// // Cancel the request
/// cancelToken.cancel();
/// ```
class CancelToken {
  bool _isCancelled = false;
  final _callbacks = <void Function()>[];

  /// Whether this token has been cancelled
  bool get isCancelled => _isCancelled;

  /// Cancels the request
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final callback in _callbacks) {
      callback();
    }
    _callbacks.clear();
  }

  /// Adds a callback to be called when cancelled
  void _addCallback(void Function() callback) {
    if (_isCancelled) {
      callback();
    } else {
      _callbacks.add(callback);
    }
  }

  /// Removes a callback
  void _removeCallback(void Function() callback) {
    _callbacks.remove(callback);
  }
}

/// Exception thrown when a request is cancelled
class CancelledException implements Exception {
  const CancelledException([this.message = 'Request was cancelled']);

  final String message;

  @override
  String toString() => 'CancelledException: $message';
}


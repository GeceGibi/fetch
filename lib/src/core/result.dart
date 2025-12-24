import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:via/src/core/request.dart';

/// Represents the result of an HTTP request, including metadata and status.
///
/// This is the base class for all HTTP result types in the Via library.
/// It contains the original request, success status, and optional timing info.
class ViaResult {
  /// Creates a new ViaResult.
  ///
  /// [request] - The original HTTP request object.
  /// [response] - The raw HTTP response (can be streamed or buffered).
  ViaResult({required this.request, required this.response});

  /// The original HTTP request that produced this result.
  final ViaRequest request;

  /// Raw HTTP response associated with this result.
  ///
  /// Can be either [http.Response] (buffered) or [http.StreamedResponse] (streaming).
  final http.BaseResponse response;

  /// True if the HTTP response status code is in the 2xx range.
  ///
  /// Indicates whether the request was considered successful by HTTP standards.
  bool get isSuccess {
    final http.BaseResponse(:statusCode) = response;
    return statusCode >= 200 && statusCode <= 299;
  }

  /// The HTTP status code of the response.
  int get statusCode => response.statusCode;

  /// The HTTP headers of the response.
  Map<String, String> get headers => response.headers;

  /// The duration of the HTTP request, if available.
  ///
  /// This is the time taken from request start to response completion.
  Duration? elapsed;

  /// Internal completer for the buffered response.
  /// This is handled lazily to remain isolate-friendly (Completers cannot be sent between isolates).
  Completer<http.Response>? _bufferedCompleter;

  Completer<http.Response> get _getBufferedCompleter {
    if (_bufferedCompleter != null) return _bufferedCompleter!;
    _bufferedCompleter = Completer<http.Response>();
    if (response is http.Response) {
      _bufferedCompleter!.complete(response as http.Response);
    }
    return _bufferedCompleter!;
  }

  /// Track if the stream has already been started.
  bool _streamStarted = false;

  /// Internal flag to track if we're currently buffering to avoid multiple fromStream calls
  bool _isBuffering = false;

  /// Internal method to buffer the stream if not already buffered.
  Future<http.Response> _buffer() async {
    final completer = _getBufferedCompleter;
    if (completer.isCompleted) return completer.future;

    if (!_isBuffering) {
      _isBuffering = true;
      try {
        if (response is http.Response) {
          if (!completer.isCompleted)
            completer.complete(response as http.Response);
        } else {
          final bufferedResponse = await http.Response.fromStream(
            response as http.StreamedResponse,
          );
          if (!completer.isCompleted) completer.complete(bufferedResponse);
          return bufferedResponse;
        }
      } catch (error, stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
        rethrow;
      } finally {
        _isBuffering = false;
      }
    }

    return completer.future;
  }

  /// Returns the response body as a String.
  ///
  /// This will consume the stream if the response is streaming.
  Future<String> get body async => (await _buffer()).body;

  /// Returns the response body as bytes.
  ///
  /// This will consume the stream if the response is streaming.
  Future<List<int>> get bodyBytes async => (await _buffer()).bodyBytes;

  /// Provides access to the response stream.
  ///
  /// If the response is already buffered ([http.Response]), it returns a single-value stream.
  /// If the response is streaming ([http.StreamedResponse]), it returns the original stream
  /// while simultaneously buffering it for later use in [body].
  /// Note: The stream can only be listened to once.
  Stream<List<int>> asStream() {
    // If we already have a buffered response (either from a pipeline or previous call)
    // return its bytes as a stream.
    if (_bufferedCompleter?.isCompleted ?? false) {
      return _bufferedCompleter!.future.asStream().map(
        (bufferedResponse) => bufferedResponse.bodyBytes,
      );
    }

    if (response is http.Response) {
      return Stream.value((response as http.Response).bodyBytes);
    }

    if (response is http.StreamedResponse) {
      if (_streamStarted) {
        throw StateError('Stream has already been listened to.');
      }
      _streamStarted = true;

      final collectedBytes = <int>[];
      final controller = StreamController<List<int>>();

      (response as http.StreamedResponse).stream.listen(
        (dataChunk) {
          collectedBytes.addAll(dataChunk);
          controller.add(dataChunk);
        },
        onDone: () {
          final completer = _getBufferedCompleter;
          if (!completer.isCompleted) {
            completer.complete(
              http.Response.bytes(
                collectedBytes,
                response.statusCode,
                headers: response.headers,
                request: response.request,
                isRedirect: response.isRedirect,
                persistentConnection: response.persistentConnection,
                reasonPhrase: response.reasonPhrase,
              ),
            );
          }

          unawaited(controller.close());
        },
        onError: (Object error, StackTrace stackTrace) {
          final completer = _getBufferedCompleter;
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }

          controller
            ..addError(error, stackTrace)
            ..close();
        },
        cancelOnError: true,
      );

      return controller.stream;
    }

    throw StateError('Response is neither StreamedResponse nor Response');
  }

  /// Returns a new [ViaResult] with a buffered [http.Response].
  ///
  /// If the response is already buffered, returns this instance.
  /// If the response is streaming, it consumes the stream and creates a new buffered result.
  Future<ViaResult> get buffered async {
    if (response is http.Response) return this;
    final bufferedResponse = await _buffer();
    final result = ViaResult(request: request, response: bufferedResponse)
      ..elapsed = elapsed;
    return result;
  }

  /// Converts the JSON response to a strongly-typed Map.
  ///
  /// [K] - The type of map keys
  /// [V] - The type of map values
  ///
  /// Returns a Map<K, V> if the JSON body is a map, throws ArgumentError otherwise.
  ///
  /// Example:
  /// ```dart
  /// final Map<String, dynamic> data = await result.asMap<String, dynamic>();
  /// ```
  Future<Map<K, V>> asMap<K, V>() async {
    final jsonBody = jsonDecode(await body);

    if (jsonBody is! Map) {
      throw ArgumentError(
        '${jsonBody.runtimeType} is not subtype of Map<$K, $V>',
        'asMap<$K, $V>',
      );
    }

    return jsonBody.cast<K, V>();
  }

  /// Converts the JSON response to a strongly-typed List.
  ///
  /// [E] - The type of list elements
  ///
  /// Returns a List<E> if the JSON body is a list, throws ArgumentError otherwise.
  ///
  /// Example:
  /// ```dart
  /// final List<String> items = await result.asList<String>();
  /// ```
  Future<List<E>> asList<E>() async {
    final jsonBody = jsonDecode(await body);

    if (jsonBody is! List) {
      throw ArgumentError(
        '${jsonBody.runtimeType} is not subtype of List<$E>',
        'asList<$E>',
      );
    }

    return jsonBody.cast<E>();
  }

  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'elapsed': elapsed?.inMilliseconds,
      'request': request.toJson(),
      'statusCode': response.statusCode,
      'headers': response.headers,
      'body': response is http.Response
          ? (response as http.Response).body
          : null,
    };
  }

  @override
  String toString() {
    return 'ViaResult(isSuccess: $isSuccess, request: $request, elapsed: $elapsed, response: $response)';
  }
}

/// A handle for an ongoing HTTP call that can be used as a Future or a Stream.
///
/// This class implements [Future], allowing it to be awaited directly to get a [ViaResult].
/// It also provides a [stream] getter to access the response as a stream of bytes.
class ViaCall<R extends ViaResult> implements Future<R> {
  ViaCall(this._executeCallback);
  final Future<R> Function({required bool isStream}) _executeCallback;

  /// Executes the request and returns the response as a stream of bytes.
  ///
  /// This automatically bypasses global runners (like Isolates) for real-time processing.
  Stream<List<int>> get stream {
    final streamController = StreamController<List<int>>();

    _executeCallback(isStream: true)
        .then((viaResult) {
          streamController.addStream(viaResult.asStream()).then((_) {
            unawaited(streamController.close());
          });
        })
        .catchError((Object error, StackTrace stackTrace) {
          streamController
            ..addError(error, stackTrace)
            ..close();
        });

    return streamController.stream;
  }

  @override
  Future<R> timeout(Duration timeLimit, {FutureOr<R> Function()? onTimeout}) {
    return _executeCallback(isStream: false).timeout(
      timeLimit,
      onTimeout: onTimeout,
    );
  }

  @override
  Future<R> catchError(Function onError, {bool Function(Object error)? test}) {
    return _executeCallback(isStream: false).catchError(
      onError,
      test: test,
    );
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(R value) onValue, {
    Function? onError,
  }) {
    return _executeCallback(isStream: false).then(
      onValue,
      onError: onError,
    );
  }

  @override
  Future<R> whenComplete(FutureOr<void> Function() action) {
    return _executeCallback(isStream: false).whenComplete(action);
  }

  @override
  @Deprecated('Use the ".stream" getter for byte streaming instead.')
  Stream<R> asStream() => _executeCallback(isStream: false).asStream();
}

/// Via exception types
enum ViaError {
  /// Request was cancelled
  cancelled,

  /// Request was debounced
  debounced,

  /// Request was throttled
  throttled,

  /// Network error (connection, timeout, etc.)
  network,

  /// HTTP error (4xx, 5xx)
  http,

  /// Custom error (extracted from response body, business logic errors)
  custom
  ;

  String get name {
    return switch (this) {
      .cancelled => 'Request Cancelled',
      .debounced => 'Request Debounced',
      .throttled => 'Request Throttled',
      .network => 'Network Error',
      .http => 'HTTP Error',
      .custom => 'Custom Error',
    };
  }
}

/// Exception thrown by Via during request or response processing.
class ViaException implements Exception {
  ViaException({
    required this.request,
    this.response,
    this.stackTrace,
    this.message = 'Via Error',
    this.type = .custom,
  });

  /// Request was explicitly cancelled by the user.
  ViaException.cancelled({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .cancelled,
       message = message ?? ViaError.cancelled.name;

  /// Request was skipped due to debouncing.
  ViaException.debounced({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .debounced,
       message = message ?? ViaError.debounced.name;

  /// Request was rejected due to throttling.
  ViaException.throttled({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .throttled,
       message = message ?? ViaError.throttled.name;

  /// Error occurred at the network layer (e.g., timeout, connection lost).
  ViaException.network({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .network,
       message = message ?? ViaError.network.name;

  /// HTTP error response (e.g., 4xx or 5xx status codes).
  ViaException.http({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .http,
       message = message ?? ViaError.http.name;

  /// Custom error defined by pipelines or [ViaExecutor.errorIf].
  ViaException.custom({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .custom,
       message = message ?? ViaError.custom.name;

  final ViaRequest request;
  final ViaError type;
  final String message;

  final http.BaseResponse? response;
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'ViaException(request: $request, type: $type, message: $message)';
  }

  Map<String, dynamic> toJson() {
    return {
      'request': request.toJson(),
      'type': type.name,
      'message': message,
      'statusCode': response?.statusCode,
      'headers': response?.headers,
      'body': response is http.Response
          ? (response as http.Response).body
          : null,
    };
  }
}

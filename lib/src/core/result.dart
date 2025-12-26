import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:via/src/core/request.dart';

/// Base class for all HTTP result types in the Via library.
///
/// Contains common metadata like request, response, status code, and headers.
abstract class ViaBaseResult {
  /// Creates a new ViaBaseResult.
  ViaBaseResult({required this.request, required this.response});

  /// The original HTTP request that produced this result.
  final ViaRequest request;

  /// Raw HTTP response associated with this result.
  final http.BaseResponse response;

  /// The HTTP status code of the response.
  int get statusCode => response.statusCode;

  /// The HTTP headers of the response.
  Map<String, String> get headers => response.headers;

  /// True if the HTTP response status code is in the 2xx range.
  bool get isSuccess => statusCode >= 200 && statusCode <= 299;

  /// The duration of the HTTP request, if available.
  Duration? elapsed;

  /// Creates a [ViaException] from this result.
  ViaException toException({
    String? message,
    ViaError type = .custom,
    StackTrace? stackTrace,
  }) {
    return ViaException(
      request: request,
      response: response,
      message: message ?? response.reasonPhrase ?? type.name,
      type: type,
      stackTrace: stackTrace,
    );
  }

  /// Converts the result metadata to a JSON-compatible Map.
  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'elapsed': elapsed?.inMilliseconds,
      'request': request.toJson(),
      'statusCode': statusCode,
      'headers': headers,
    };
  }
}

/// Represents a buffered HTTP response where the entire body is in memory.
///
/// This is the default result type for standard HTTP requests.
/// It provides methods for parsing the body as JSON (Map or List).
class ViaResult extends ViaBaseResult {
  /// Creates a new buffered ViaResult.
  ViaResult({required super.request, required http.Response response})
      : super(response: response);

  @override
  http.Response get response => super.response as http.Response;

  /// The response body as a String.
  String get body => response.body;

  /// The response body as bytes.
  List<int> get bodyBytes => response.bodyBytes;

  /// Converts the JSON response to a strongly-typed Map.
  Future<Map<K, V>> asMap<K, V>() async {
    final jsonBody = jsonDecode(body);
    if (jsonBody is! Map) {
      throw ArgumentError(
        '${jsonBody.runtimeType} is not subtype of Map<$K, $V>',
        'asMap<$K, $V>',
      );
    }
    return jsonBody.cast<K, V>();
  }

  /// Converts the JSON response to a strongly-typed Map and maps it to a model.
  Future<T> to<T>(T Function(Map<String, dynamic> json) mapper) async {
    final map = await asMap<String, dynamic>();
    return mapper(map);
  }

  /// Converts the JSON response to a strongly-typed List.
  Future<List<E>> asList<E>() async {
    final jsonBody = jsonDecode(body);
    if (jsonBody is! List) {
      throw ArgumentError(
        '${jsonBody.runtimeType} is not subtype of List<$E>',
        'asList<$E>',
      );
    }
    return jsonBody.cast<E>();
  }

  /// Converts the JSON response to a strongly-typed List and maps each item to a model.
  Future<List<T>> toListOf<T>(
    T Function(Map<String, dynamic> json) mapper,
  ) async {
    final list = await asList<Map<String, dynamic>>();
    return list.map(mapper).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'body': body,
    };
  }

  @override
  String toString() {
    return 'ViaResult(isSuccess: $isSuccess, request: $request, elapsed: $elapsed, statusCode: $statusCode)';
  }
}

/// Represents a streaming HTTP response.
///
/// This is used when the response body should be processed as a stream of bytes
/// rather than being buffered into memory.
class ViaResultStream extends ViaBaseResult {
  /// Creates a new streaming ViaResult.
  ViaResultStream({
    required super.request,
    required http.StreamedResponse response,
  }) : super(response: response);

  @override
  http.StreamedResponse get response => super.response as http.StreamedResponse;

  /// The response body as a stream of bytes.
  /// Note: The stream can only be listened to once.
  Stream<List<int>> get stream => response.stream;

  /// Creates a copy of this result with a new stream.
  ViaResultStream copyWith({Stream<List<int>>? stream}) {
    if (stream == null) return this;

    return ViaResultStream(
      request: request,
      response: http.StreamedResponse(
        stream,
        statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      ),
    )..elapsed = elapsed;
  }

  @override
  String toString() {
    return 'ViaResultStream(isSuccess: $isSuccess, request: $request, statusCode: $statusCode)';
  }
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
  custom;

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

  /// Custom error defined by pipelines.
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

  /// The HTTP status code from the response, if available.
  int? get statusCode => response?.statusCode;

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
          ? (response! as http.Response).body
          : null,
    };
  }
}

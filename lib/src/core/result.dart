import 'dart:async';
import 'dart:convert';

import 'package:fetch/src/core/request.dart';
import 'package:http/http.dart' as http;

/// Represents the result of an HTTP request, including metadata and status.
///
/// This is the base class for all HTTP result types in the Fetch library.
/// It contains the original request, success status, and optional timing info.
sealed class FetchResult {
  /// Creates a new FetchResult.
  ///
  /// [request] - The original HTTP request object.
  /// [isSuccess] - True if the HTTP status code is 2xx, otherwise false.
  /// [elapsed] - Optional duration for the request (in milliseconds).
  FetchResult({required this.request, required this.isSuccess});

  /// Factory constructor for a successful HTTP result.
  ///
  /// [request] - The original HTTP request.
  /// [response] - The HTTP response object.
  /// [elapsed] - Optional duration for the request.
  factory FetchResult.success({
    required FetchRequest request,
    required http.Response response,
  }) = FetchResultSuccess;

  /// The original HTTP request that produced this result.
  final FetchRequest request;

  /// True if the HTTP response status code is in the 2xx range.
  ///
  /// Indicates whether the request was considered successful by HTTP standards.
  final bool isSuccess;

  /// The duration of the HTTP request, if available.
  ///
  /// This is the time taken from request start to response completion.
  final List<Duration> elapsed = [];

  @override
  String toString() {
    return 'FetchResult(isSuccess: $isSuccess, request: $request, elapsed: $elapsed)';
  }

  /// Converts this result to a JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'elapsed': elapsed.map((e) => e.inMilliseconds).toList(),
      'request': request.toJson(),
    };
  }
}

class FetchResultSuccess implements FetchResult {
  FetchResultSuccess({required this.request, required this.response});

  final http.Response response;

  @override
  final List<Duration> elapsed = [];

  @override
  bool get isSuccess {
    final http.Response(:statusCode) = response;
    return statusCode >= 200 && statusCode <= 299;
  }

  @override
  final FetchRequest request;

  /// Converts the JSON response to a strongly-typed Map.
  ///
  /// [K] - The type of map keys
  /// [V] - The type of map values
  ///
  /// Returns a Map<K, V> if the JSON body is a map, throws ArgumentError otherwise.
  ///
  /// Example:
  /// ```dart
  /// final Map<String, dynamic> data = await response.asMap<String, dynamic>();
  /// ```
  FutureOr<Map<K, V>> asMap<K, V>() async {
    final jsonBody = jsonDecode(response.body);

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
  /// final List<String> items = await response.asList<String>();
  /// ```
  FutureOr<List<E>> asList<E>() async {
    final jsonBody = jsonDecode(response.body);

    if (jsonBody is! List) {
      throw ArgumentError(
        '${jsonBody.runtimeType} is not subtype of List<$E>',
        'asList<$E>',
      );
    }

    return jsonBody.cast<E>();
  }

  @override
  String toString() {
    return 'FetchResultSuccess(isSuccess: $isSuccess, request: $request, elapsed: $elapsed, response: $response)';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'elapsed': elapsed.map((e) => e.inMilliseconds).toList(),
      'request': request.toJson(),
      'statusCode': response.statusCode,
      'headers': response.headers,
      'body': response.body,
    };
  }
}

/// Fetch exception types
enum FetchError {
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

class FetchResultError implements FetchResult, Exception {
  FetchResultError({
    required this.request,
    this.response,

    this.stackTrace,
    this.message = 'Fetch Error',
    this.type = .custom,
  });

  FetchResultError.cancelled({
    required this.request,
    this.response,

    this.stackTrace,
    String? message,
  }) : type = .cancelled,
       message = message ?? FetchError.cancelled.name;

  FetchResultError.debounced({
    required this.request,
    this.response,

    this.stackTrace,
    String? message,
  }) : type = .debounced,
       message = message ?? FetchError.debounced.name;

  FetchResultError.throttled({
    required this.request,
    this.response,

    this.stackTrace,
    String? message,
  }) : type = .throttled,
       message = message ?? FetchError.throttled.name;

  FetchResultError.network({
    required this.request,
    this.response,

    this.stackTrace,
    String? message,
  }) : type = .network,
       message = message ?? FetchError.network.name;

  FetchResultError.http({
    required this.request,
    this.response,

    this.stackTrace,
    String? message,
  }) : type = .http,
       message = message ?? FetchError.http.name;

  FetchResultError.custom({
    required this.request,
    this.response,

    this.stackTrace,
    String? message,
  }) : type = .custom,
       message = message ?? FetchError.custom.name;

  final StackTrace? stackTrace;
  final FetchError type;
  final String message;

  final http.Response? response;

  @override
  final List<Duration> elapsed = [];

  @override
  final bool isSuccess = false;

  @override
  final FetchRequest request;

  @override
  String toString() {
    return 'FetchResultError(isSuccess: $isSuccess, request: $request, elapsed: $elapsed, type: $type, message: $message)';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'elapsed': elapsed.map((e) => e.inMilliseconds).toList(),
      'request': request.toJson(),
      'type': type.name,
      'message': message,
    };
  }
}

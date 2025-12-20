import 'dart:async';
import 'dart:convert';

import 'package:fetch/src/core/request.dart';
import 'package:http/http.dart' as http;

/// Represents the result of an HTTP request, including metadata and status.
///
/// This is the base class for all HTTP result types in the Fetch library.
/// It contains the original request, success status, and optional timing info.
class FetchResult {
  /// Creates a new FetchResult.
  ///
  /// [request] - The original HTTP request object.
  /// [isSuccess] - True if the HTTP status code is 2xx, otherwise false.
  /// [elapsed] - Optional duration for the request (in milliseconds).
  FetchResult({required this.request, required this.response});

  /// The original HTTP request that produced this result.
  final FetchRequest request;

  /// True if the HTTP response status code is in the 2xx range.
  ///
  /// Indicates whether the request was considered successful by HTTP standards.
  bool get isSuccess {
    final http.Response(:statusCode) = response;
    return statusCode >= 200 && statusCode <= 299;
  }

  /// The duration of the HTTP request, if available.
  ///
  /// This is the time taken from request start to response completion.
  Duration? elapsed;

  /// Raw HTTP response associated with this result.
  ///
  /// Only available in FetchResult
  final http.Response response;

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

  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'elapsed': elapsed?.inMilliseconds,
      'request': request.toJson(),
      'statusCode': response.statusCode,
      'headers': response.headers,
      'body': response.body,
    };
  }

  @override
  String toString() {
    return 'FetchResultSuccess(isSuccess: $isSuccess, request: $request, elapsed: $elapsed, response: $response)';
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

class FetchException implements Exception {
  FetchException({
    required this.request,
    this.response,
    this.stackTrace,
    this.message = 'Fetch Error',
    this.type = .custom,
  });

  FetchException.cancelled({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .cancelled,
       message = message ?? FetchError.cancelled.name;

  FetchException.debounced({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .debounced,
       message = message ?? FetchError.debounced.name;

  FetchException.throttled({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .throttled,
       message = message ?? FetchError.throttled.name;

  FetchException.network({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .network,
       message = message ?? FetchError.network.name;

  FetchException.http({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .http,
       message = message ?? FetchError.http.name;

  FetchException.custom({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .custom,
       message = message ?? FetchError.custom.name;

  final FetchRequest request;
  final FetchError type;
  final String message;

  final http.Response? response;
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'FetchResultError(request: $request, type: $type, message: $message)';
  }

  Map<String, dynamic> toJson() {
    return {'request': request.toJson(), 'type': type.name, 'message': message};
  }
}

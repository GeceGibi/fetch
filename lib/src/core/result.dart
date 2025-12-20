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
  /// [isSuccess] - True if the HTTP status code is 2xx, otherwise false.
  /// [elapsed] - Optional duration for the request (in milliseconds).
  ViaResult({required this.request, required this.response});

  /// The original HTTP request that produced this result.
  final ViaRequest request;

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
  /// Only available in ViaResult
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
    return 'ViaResult(isSuccess: $isSuccess, request: $request, elapsed: $elapsed, response: $response)';
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

class ViaException implements Exception {
  ViaException({
    required this.request,
    this.response,
    this.stackTrace,
    this.message = 'Via Error',
    this.type = .custom,
  });

  ViaException.cancelled({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .cancelled,
       message = message ?? ViaError.cancelled.name;

  ViaException.debounced({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .debounced,
       message = message ?? ViaError.debounced.name;

  ViaException.throttled({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .throttled,
       message = message ?? ViaError.throttled.name;

  ViaException.network({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .network,
       message = message ?? ViaError.network.name;

  ViaException.http({
    required this.request,
    this.response,
    this.stackTrace,
    String? message,
  }) : type = .http,
       message = message ?? ViaError.http.name;

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

  final http.Response? response;
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
      'statusCode': ?response?.statusCode,
      'headers': ?response?.headers,
      'body': ?response?.body,
    };
  }
}

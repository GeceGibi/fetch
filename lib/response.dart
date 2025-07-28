part of 'fetch.dart';

class FetchResponse {
  FetchResponse(this.response, {this.postBody, this.elapsed});
  final http.Response response;

  /// Whether the response indicates a successful HTTP status.
  ///
  /// Returns true if the status code is between 200 and 299 (inclusive).
  bool get isSuccess {
    return response.statusCode >= 200 && response.statusCode <= 299;
  }

  /// Request duration (time taken to complete the request)
  Duration? elapsed;

  /// The original request body (for logging purposes)
  final Object? postBody;

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
}

/// Enhanced HTTP response class with JSON parsing capabilities.
///
/// This class extends the standard http.Response with additional features:
/// - JSON body parsing
/// - Request timing information
/// - Success status checking
/// - Type-safe JSON conversion methods
// class FetchResponse extends http.Response with FetchJsonResponse {
//   /// Creates a new FetchResponse from an http.Response.
//   ///
//   /// [response] - The original HTTP response
//   /// [encoding] - Character encoding for response body (default: utf8)
//   /// [postBody] - The original request body (for logging purposes)
//   /// [elapsed] - Request duration (for timing information)
//   FetchResponse.fromResponse(
//     http.Response response, {
//     this.encoding = utf8,
//     this.postBody,
//     this.elapsed,
//   }) : super.bytes(
//           response.bodyBytes,
//           response.statusCode,
//           request: response.request,
//           headers: response.headers,
//           isRedirect: response.isRedirect,
//           persistentConnection: response.persistentConnection,
//           reasonPhrase: response.reasonPhrase,
//         );

//   /// Whether the response indicates a successful HTTP status.
//   ///
//   /// Returns true if the status code is between 200 and 299 (inclusive).
//   bool get isSuccess {
//     return statusCode >= 200 && statusCode <= 299;
//   }

//   /// Request duration (time taken to complete the request)
//   Duration? elapsed;

//   /// Character encoding used for the response body
//   Encoding encoding;

//   /// The original request body (for logging purposes)
//   final Object? postBody;

//   /// Parses the response body as JSON.
//   ///
//   /// Returns the parsed JSON object. Throws an exception if the body
//   /// is not valid JSON or if the encoding fails.
//   @override
//   dynamic get jsonBody => jsonDecode(encoding.decode(bodyBytes))!;
// }

/// Mixin that provides type-safe JSON conversion methods.
///
/// This mixin adds methods to convert JSON responses to strongly-typed
/// Dart objects with proper error handling.

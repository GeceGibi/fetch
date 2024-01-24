part of 'fetch.dart';

/// http.Response exportation
typedef HttpResponse = http.Response;

/// Base fetch response
class FetchResponse {
  // ignore: public_member_api_docs
  const FetchResponse(
    this.data, {
    this.message,
    this.isOk = false,
    this.httpResponse,
    this.uri,
  });

  // ignore: public_member_api_docs
  factory FetchResponse.fromHandler(
    HttpResponse? response,
    Object? error,
    Uri? uri,
  ) {
    if (error != null || response == null) {
      return FetchResponse(
        null,
        httpResponse: response,
        message: '$error',
        uri: uri,
      );
    }

    return FetchResponse(
      FetchHelpers.handleResponseBody(response),
      isOk: FetchHelpers.isOk(response),
      message: response.reasonPhrase ?? error.toString(),
      httpResponse: response,
      uri: uri,
    );
  }

  final Object? data;

  T cast<T>() {
    if (data is T) {
      return data! as T;
    }

    throw Exception('data type is not of $T');
  }

  final Uri? uri;
  final bool isOk;
  final String? message;
  final HttpResponse? httpResponse;

  @override
  String toString() {
    return 'FetchResponse(data: $data, isOk: $isOk, message: $message, httpResponse: $httpResponse)';
  }
}

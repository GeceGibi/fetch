part of fetch;

typedef HttpResponse = http.Response;

class FetchResponse {
  const FetchResponse(
    this.data, {
    this.message,
    this.isOk = false,
    this.httpResponse,
    this.uri,
  });

  factory FetchResponse.fromHandler(
    HttpResponse? response,
    Object? error,
    Uri? uri,
  ) {
    if (error != null || response == null) {
      return FetchResponse(
        null,
        message: '$error',
        httpResponse: response,
        isOk: false,
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

  final dynamic data;

  T as<T>() {
    if (data is T) {
      return data;
    }

    throw 'data is not type of $T';
  }

  final bool isOk;
  final String? message;
  final HttpResponse? httpResponse;
  final Uri? uri;

  @override
  String toString() {
    return 'FetchResponse(data: $data, isOk: $isOk, message: $message, httpResponse: $httpResponse)';
  }
}

part of fetch;

typedef HttpResponse = http.Response;

class FetchResponse {
  const FetchResponse(
    this.data, {
    this.message,
    this.isOk = false,
    this.httpResponse,
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
      );
    }

    return FetchResponse(
      FetchHelpers.handleResponseBody(response),
      isOk: FetchHelpers.isOk(response),
      message: response.reasonPhrase ?? error.toString(),
      httpResponse: response,
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

  @override
  String toString() {
    return 'FetchResponse(data: $data, isOk: $isOk, message: $message, httpResponse: $httpResponse)';
  }
}

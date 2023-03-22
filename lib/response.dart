part of fetch;

typedef HttpResponse = http.Response;

abstract class FetchResponseBase {
  const FetchResponseBase(
    this.data, {
    this.message,
    this.isOk = false,
    this.httpResponse,
  });

  final dynamic data;

  T as<T>() {
    if (data is T) {
      return data;
    }

    throw 'data is not $T';
  }

  final bool isOk;
  final String? message;
  final HttpResponse? httpResponse;

  @override
  String toString() {
    return 'FetchResponse(data: $data, isOk: $isOk, message: $message, httpResponse: $httpResponse)';
  }
}

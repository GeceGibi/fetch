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
  final bool isOk;
  final String? message;
  final HttpResponse? httpResponse;

  @override
  String toString() {
    return 'FetchResponse(data: $data, isOk: $isOk, message: $message, httpResponse: $httpResponse)';
  }
}

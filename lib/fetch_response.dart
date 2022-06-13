part of fetch;

typedef HttpResponse = http.Response;

abstract class FetchResponseBase<T extends Object?> {
  FetchResponseBase(
    this.payload, {
    required this.message,
    required this.isSuccess,
  });

  FetchResponseBase.error([this.message])
      : isSuccess = false,
        payload = null;

  final bool isSuccess;
  final String? message;
  final T? payload;

  @override
  String toString() {
    return 'FetchResponse<${payload.runtimeType}>(payload: $payload, message: $message, isSuccess: $isSuccess)';
  }
}

class DefaultFetchResponse<T> extends FetchResponseBase<T> {
  DefaultFetchResponse(
    super.payload, {
    required super.message,
    required super.isSuccess,
  });

  DefaultFetchResponse.error([String? error]) : super.error(error);
}

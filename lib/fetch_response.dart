part of fetch;

typedef HttpResponse = http.Response;

class FetchResponse<T extends Object?> {
  FetchResponse(
    this.payload, {
    required this.message,
    required this.isSuccess,
    required this.params,
  });

  FetchResponse.error([this.message])
      : isSuccess = false,
        payload = null,
        params = const {};

  final FetchParams params;
  final bool isSuccess;
  final String? message;
  final T? payload;

  @override
  String toString() {
    return 'FetchResponse<$T>(payload: $payload, message: $message, isSuccess: $isSuccess)';
  }
}

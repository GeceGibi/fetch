part of fetch;

typedef HttpResponse = http.Response;

class FetchResponse<T extends Object?> {
  FetchResponse(
    this.body, {
    required this.message,
    required this.isSuccess,
    required this.params,
  });

  FetchResponse.error([this.message])
      : body = null,
        isSuccess = false,
        params = const {};

  final FetchParams params;
  final bool isSuccess;
  final String? message;
  final T? body;

  @override
  String toString() {
    return 'FetchResponse<$T>(body: $body, message: $message, isSuccess: $isSuccess)';
  }
}

part of fetch;

typedef HttpResponse = http.Response;

class FetchResponse<T> {
  const FetchResponse.success({
    this.data,
    this.message,
    this.isSuccess = false,
  });
  const FetchResponse.error(this.message)
      : isSuccess = false,
        data = null;

  final T? data;
  final bool isSuccess;
  final String? message;
  T get requireData => data!;

  @override
  String toString() {
    return 'FetchResponse(data: $data, isSuccess: $isSuccess, message: $message)';
  }
}

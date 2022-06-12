part of fetch;

typedef HttpResponse = http.Response;

abstract class FetchResponse<T extends Object?> {
  FetchResponse(
    this.payload, {
    required this.message,
    required this.isSuccess,
  });

  FetchResponse.error([String? error])
      : isSuccess = false,
        message = error,
        payload = null;

  final bool isSuccess;
  final String? message;
  final T? payload;

  FetchResponse copyWith({
    T? payload,
    bool? isSuccess,
    String? message,
  });
}

class DefaultFetchResponse<T> extends FetchResponse<T> {
  DefaultFetchResponse(
    super.payload, {
    required super.message,
    required super.isSuccess,
  });

  DefaultFetchResponse.error([String? error])
      : super(null, isSuccess: false, message: error);

  @override
  FetchResponse<T> copyWith({
    T? payload,
    bool? isSuccess,
    String? message,
    int? responseCode,
  }) {
    return DefaultFetchResponse<T>(
      payload ?? this.payload,
      isSuccess: isSuccess ?? this.isSuccess,
      message: message ?? this.message,
    );
  }
}

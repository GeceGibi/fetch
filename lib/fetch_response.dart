part of fetch;

class FetchResponse<T extends Object?> {
  FetchResponse(
    this.payload, {
    required this.message,
    required this.isSuccess,
  });

  FetchResponse.error([String? error])
      : isSuccess = false,
        message = error,
        payload = null;

  static FetchResponse<K> fromJson<K>(dynamic json) {
    switch (json.runtimeType) {
      case Map:
        return FetchResponse<K>(
          json,
          message: json['message'],
          isSuccess: true,
        );

      default:
        return FetchResponse<K>(
          json,
          message: null,
          isSuccess: true,
        );
    }
  }

  final bool isSuccess;
  final String? message;
  final T? payload;

  FetchResponse copyWith({
    T? payload,
    bool? isSuccess,
    String? message,
  }) {
    return FetchResponse(
      payload ?? this.payload,
      isSuccess: isSuccess ?? this.isSuccess,
      message: message ?? this.message,
    );
  }
}

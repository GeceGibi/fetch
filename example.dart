import 'dart:convert';
import 'package:fetch/fetch.dart';

var _utf8Decoder = const Utf8Decoder();

class CustomResponse<T> extends FetchResponse<T> {
  CustomResponse(
    super.payload, {
    required super.message,
    required super.isSuccess,
    required this.code,
  });

  CustomResponse.error([String? error])
      : code = -1,
        super(null, isSuccess: false, message: null);

  final int code;

  @override
  String toString() {
    return 'CustomResponse(response: ${super.payload}, code: $code, message: ${super.message}, isSuccess: ${super.isSuccess})';
  }

  @override
  FetchResponse<T?> copyWith({
    T? payload,
    bool? isSuccess,
    String? message,
    int? code,
  }) {
    return CustomResponse(
      payload ?? this.payload,
      code: code ?? this.code,
      message: message ?? this.message,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ExampleConfig extends FetchConfig {
  @override
  Uri get base => Uri.parse('https://dummyjson.com');

  @override
  Future<R> responseHandler<R extends FetchResponse<T>, T>(
    HttpResponse response,
    Mapper<T> mapper, [
    FetchParams? body,
  ]) async {
    var responseShink = CustomResponse<T>.error(response.reasonPhrase);

    if (isOk(response)) {
      T payload;

      if (response.headers.containsKey('content-type') &&
          response.headers['content-type']!.contains('application/json')) {
        payload = await mapper(
          jsonDecode(_utf8Decoder.convert(response.bodyBytes)),
        );
      } else {
        payload = await mapper(response.body);
      }

      responseShink = CustomResponse<T>(
        payload,
        isSuccess: true,
        message: null,
        code: -1,
      );
    }

    return responseShink as R;
  }
}

class CustomFetch<T> extends Fetch<T, CustomResponse<T>> {
  CustomFetch(super.endpoint);
}

void main(List<String> args) async {
  final config = ExampleConfig();

  config.apply();
  // ignore: avoid_print
  config.onFetch.listen(print);

  final response = await CustomFetch('/products/1').get();

  response.code;
}

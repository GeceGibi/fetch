import 'dart:async';
import 'dart:convert';
import 'package:fetch/fetch.dart';

var _utf8Decoder = const Utf8Decoder();

class CustomResponse<T> extends FetchResponseBase<T> {
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
}

class ExampleResponse<T> extends CustomResponse<T> {
  ExampleResponse(
    super.payload, {
    required super.message,
    required super.isSuccess,
    required super.code,
    required this.deneme,
  });

  ExampleResponse.error([super.error])
      : deneme = const [],
        super.error();

  final List<Map<String, dynamic>> deneme;
}

class ExampleConfig extends FetchConfig {
  @override
  Uri get base => Uri.parse('https://dummyjson.com');

  @override
  Future<R> responseHandler<R extends FetchResponseBase<T?>, T>(
    HttpResponse response,
    Mapper<T> mapper, [
    FetchParams? body,
  ]) async {
    if (isOk(response)) {
      final payload = await mapper(
        jsonDecode(_utf8Decoder.convert(response.bodyBytes)),
      );

      return ExampleResponse<T>(
        payload,
        isSuccess: true,
        message: null,
        code: -1,
        deneme: [],
      ) as R;
    }

    return ExampleResponse.error(response.reasonPhrase) as R;
  }
}

class CustomConfig extends ExampleConfig {
  @override
  Future<R> responseHandler<R extends FetchResponseBase<T?>, T>(
    HttpResponse response,
    Mapper<T> mapper, [
    FetchParams? body,
  ]) async {
    if (isOk(response)) {
      final payload = await mapper(
        jsonDecode(_utf8Decoder.convert(response.bodyBytes)),
      );

      return CustomResponse<T>(
        payload,
        isSuccess: true,
        message: null,
        code: -1,
      ) as R;
    }

    return CustomResponse.error(response.reasonPhrase) as R;
  }
}

final onFetchController = StreamController();
final exampleConfig = ExampleConfig();

class CustomFetch<T> extends FetchBase<T, CustomResponse<T>> {
  CustomFetch(super.endpoint, {super.mapper}) : super(config: exampleConfig);
}

class ExampleFetch<T> extends FetchBase<T, ExampleResponse<T>> {
  ExampleFetch(super.endpoint, {super.mapper}) : super(config: ExampleConfig());
}

class PayloadFromJson {
  PayloadFromJson.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'];

  final int id;
  final String title;
}

void main(List<String> args) async {
  // exampleConfig.onFetch.listen(print);

  final custom = await CustomFetch<Map<String, dynamic>>('/{type}/1').get(
    params: {
      'type': 'products',
    },
  );

  final example = await ExampleFetch(
    '/products/{id}',
    mapper: (json) => PayloadFromJson.fromJson(json as Map<String, dynamic>),
  ).get(params: {'id': 2});

  print(custom.payload);
  print(example.deneme);
}

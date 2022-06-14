import 'dart:async';
import 'dart:convert';
import 'package:fetch/fetch.dart';

const _utf8Decoder = Utf8Decoder();

class ExampleConfig extends FetchConfig {
  @override
  Uri get base => Uri.parse('https://dummyjson.com');

  @override
  Future<R> responseHandler<R extends FetchResponse<T?>, T>(
    HttpResponse response,
    Mapper<T> mapper, [
    FetchParams? body,
  ]) async {
    var responseShink = ExampleResponse<T>.error(
      '${response.statusCode} - ${response.reasonPhrase}',
    );

    if (await isSuccess(response)) {
      T payload;

      if (response.headers.containsKey('content-type') &&
          response.headers['content-type']!.contains('application/json')) {
        final json = jsonDecode(_utf8Decoder.convert(response.bodyBytes));
        payload = await mapper(json);
      } else {
        payload = await mapper(response.body);
      }

      responseShink = ExampleResponse<T>(
        payload,
        isSuccess: true,
        message: null,
        deneme: [
          {'payload.hashCode': payload.hashCode}
        ],
      );
    }

    return responseShink as R;
  }
}

class ExampleResponse<T> extends FetchResponse<T> {
  ExampleResponse(
    super.payload, {
    required super.message,
    required super.isSuccess,
    required this.deneme,
  });

  ExampleResponse.error([super.error])
      : deneme = const [],
        super.error();

  final List<Map<String, dynamic>> deneme;
}

class ExampleFetch<T> extends FetchBase<T, ExampleResponse<T>> {
  ExampleFetch(super.endpoint, {super.mapper, super.config});
}

class PayloadFromJson {
  PayloadFromJson.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'];

  final int id;
  final String title;
}

class CopyFromExamplate extends ExampleConfig {
  @override
  Uri get base => Uri.parse('https://www.google.com');
}

void main(List<String> args) async {
  final config = ExampleConfig();

  Fetch.setConfig(config);

  config.onFetch.listen((event) {
    print('LOGGER:::$event');
  });

  try {
    final response = await ExampleFetch(
      '/products/{id}',
      mapper: (json) => PayloadFromJson.fromJson(json as Map<String, dynamic>),
      config: CopyFromExamplate(),
    ).get(params: {'id': 2});

    print(response);
  } on FetchResponse catch (e) {
    print(e);
  }
}

import 'package:fetch/fetch.dart';

class ExampleConfig extends FetchConfig {
  @override
  Uri get base => Uri.parse('https://dummyjson.com');

  @override
  Future<R> responseHandler<R extends FetchResponse<T?>, T>(
    HttpResponse response,
    Mapper<T> mapper, [
    FetchParams? body,
  ]) async {
    if (await isSuccess(response)) {
      return ExampleResponse<T>(
        await mapper(payloadBuilder(response)),
        isSuccess: true,
        message: null,
        deneme: [
          {'response': response}
        ],
      ) as R;
    }

    return ExampleResponse<T>.error(
      '${response.statusCode} - ${response.reasonPhrase}',
    ) as R;
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
        todo = json['todo'];

  final int id;
  final String todo;
}

void main(List<String> args) async {
  final config = ExampleConfig();

  Fetch.setConfig(config);

  config.onFetch.listen((event) {
    print('LOGGER:::$event');
  });

  // Fetch.getURL('https://www.{host}.com/?deneme=query', params: {
  //   'host': 'google',
  //   'test': 'Fetch',
  // });

  try {
    final response = await ExampleFetch(
      '/todos/{id}',
      mapper: (json) => PayloadFromJson.fromJson(json as Map<String, dynamic>),
    ).get(
      params: {
        'id': 2,
        'deneme': 123,
        'value': 1.0,
      },
    );

    print(response.payload?.todo);
  } on FetchResponse catch (e) {
    print(e);
  }
}

import 'package:fetch/fetch.dart';

class TestConfig extends FetchConfig {
  @override
  Uri get baseUri => Uri.parse('https://jsonplaceholder.typicode.com');

  @override
  bool get loggerEnabled => true;
}

void main(List<String> args) async {
  final config = TestConfig();

  Fetch.setConfig(config);

  config.onFetch.listen((event) {
    print('event from stream: $event');
  });

  await Fetch<Map>('/todos/1').get();
}

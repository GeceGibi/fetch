import 'package:fetch/fetch.dart';

class CustomResponse extends FetchResponse {
  CustomResponse(
    super.data, {
    super.message,
    super.isOk,
    super.httpResponse,
    required super.uri,
  });
}

void main(List<String> args) async {
  final fetch = Fetch(
    base: 'https://api.gece.dev',
    headerBuilder: () {
      return {
        'content-type': 'application/json',
      };
    },
    enableLogs: false,
    beforeRequest: (uri) async {
      await Future.delayed(const Duration(seconds: 1));
      //print('Before Request');
    },
    afterRequest: (_, __) {
      //print('After Request');
    },
    shouldRequest: (uri, headers) {
      if (uri.queryParameters.containsKey('foo')) {
        throw 'test query params founded.';
      }

      return true;
    },
    handler: FetchResponse.fromHandler,
  );

  final response = await fetch.get('/info', queryParams: {'bar': 1});
  print(response);

  await fetch.get('/info', queryParams: {'bar': 1});

  // print(response.data);
  // print(response.data);
  // fetch.post('/posts', jsonEncode({'foo': 1}));
}

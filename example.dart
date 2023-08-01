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
    enableLogs: true,
    overrides: FetchOverride(
      post: (method, uri, body, headers) {
        return method(uri, body: body, headers: headers);
      },
    ),
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

  await fetch.get('/info');

  // print(response.data);
  // print(response.data);
  // fetch.post('/posts', jsonEncode({'foo': 1}));
}

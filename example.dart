import 'dart:isolate';

import 'package:fetch/fetch.dart';

class CustomResponse extends FetchResponse {
  CustomResponse(
    super.data, {
    required super.uri,
    super.message,
    super.isOk,
    super.httpResponse,
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
    overrides: FetchOverride(
      post: (method, uri, body, headers) async {
        return Isolate.run(() => method(uri, body: body, headers: headers));
      },
      get: (method, uri, headers) async {
        return Isolate.run(() => method(uri, headers: headers));
      },
    ),
    beforeRequest: (uri) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      print('Before Request');
    },
    afterRequest: (_, __) {
      print('After Request');
    },
    shouldRequest: (uri, headers) {
      if (uri.queryParameters.containsKey('foo')) {
        throw 'foo founded !!';
      }

      return true;
    },
    handler: FetchResponse.fromHandler,
  );

  final response = await fetch.get('/info');

  print(response.asList<int>());

  // print(response.data );
  // print(response.data);
  // fetch.post('/posts', jsonEncode({'foo': 1}));
}

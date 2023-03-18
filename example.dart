import 'package:fetch/fetch.dart';

void main(List<String> args) async {
  final fetch = Fetch(
    base: 'https://api.gece.dev',
    headers: {'content-type': 'application/json'},
    enableLogs: true,
    beforeRequest: (uri) {
      print('Before Request');
    },
    afterRequest: (_, __) {
      print('After Request');
    },
    shouldRequest: (uri, headers) {
      if (uri.queryParameters.containsKey('foo')) {
        throw 'test query params founded.';
      }

      return true;
    },
    handler: <T>(response, error, uri) {
      if (error != null || response == null) {
        return FetchResponse.error('$error');
      }

      return FetchResponse<T>.success(
        data: FetchHelpers.handleResponseBody(response),
        isSuccess: FetchHelpers.isSuccess(response.statusCode),
        message: response.reasonPhrase ?? error.toString(),
      );
    },
  );

  await fetch.get<Map>('/info', queryParams: {'bar': 1});
  await fetch.get<Map>('/info', queryParams: {'bar': 1});

  // print(response.data);
  // print(response.data);
  // fetch.post('/posts', jsonEncode({'foo': 1}));
}

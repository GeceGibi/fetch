import 'package:fetch/fetch.dart';

void main(List<String> args) async {
  final fetch = Fetch(
    from: 'https://api.gece.deV',
    headers: {
      'content-type': 'application/json',
    },
    handler: <T>(response, error) {
      return FetchResponse<T>.success(
        data: response!.bodyBytes as T,
      );
    },
  );

  fetch.enableLogger = true;

  final response = await fetch.get('/info');
  print(response.data);
  // fetch.post('/posts', jsonEncode({'foo': 1}));
}

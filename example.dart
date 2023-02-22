import 'package:fetch/fetch.dart';

void main(List<String> args) async {
  final fetch = Fetch(
    from: 'https://api.gece.deV',
    headers: {'content-type': 'application/json'},
    // shouldRequest: (uri, headers) {
    //   throw 'Throw example';
    // },
    handler: <T>(response, error) {
      if (error != null) {
        return FetchResponse.error('$error');
      }

      return FetchResponse<T>.success(
        data: response!.bodyBytes as T,
      );
    },
  );

  fetch.enableLogger = true;

  final response = await fetch.get('/info', queryParams: {'deneme': 1});

  print(response.message);
  // print(response.data);
  // fetch.post('/posts', jsonEncode({'foo': 1}));
}

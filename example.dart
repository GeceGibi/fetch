import 'dart:isolate';

import 'package:fetch/fetch.dart';

// class IResponse {
//   IResponse(this.ok);
//   final int ok;
// }

void main(List<String> args) async {
  final fetch = Fetch<FetchResponse>(
    base: Uri.parse('https://api.gece.dev'),
    headerBuilder: () {
      return {
        'content-type': 'application/json',
      };
    },
    enableLogs: true,
    override: (payload, method) {
      return Isolate.run(() => method(payload));
    },
    // transform: (response) async {
    //   return Isolate.run(() => response.asJson());
    // },
  );

  final response = await fetch.get('/info', queryParams: {
    'foo2': 1,
  });

  //  print(response.describe());

  //  print(response.describe());

  // print(response.asMap<String, dynamic>());

  // print(response.data );
  // print(response.data);
  // fetch.post('/posts', jsonEncode({'foo': 1}));
}

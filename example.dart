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
    // timeout: Duration.zero,
    enableLogs: true,
    override: (payload, method) {
      return Isolate.run(() => method(payload));
    },
    transform: (response) {
      // print(response.error);

      return response;
      // return Isolate.run(() => response.asJson());
    },
  );

  final r1 = await fetch.get(
    '/info',
    cacheOptions: CacheOptions(duration: Duration(seconds: 10)),
    queryParams: {
      'foo2': 1,
    },
  );

  final r2 = await fetch.get(
    '/info',
    cacheOptions: CacheOptions(duration: Duration(seconds: 10)),
    queryParams: {
      'foo2': 1,
    },
  );

  print([r1.elapsed, r2.elapsed]);
}

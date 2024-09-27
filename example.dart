import 'dart:async';
import 'dart:isolate';

import 'package:fetch/fetch.dart';

class IResponse extends FetchResponse {
  IResponse.fromResponse(
    super.response, {
    super.elapsed,
    super.encoding,
    super.postBody,
  }) : super();

  @override
  FutureOr<List<E>> asList<E>() {
    return Isolate.run(() => super.asList());
  }

  @override
  FutureOr<Map<K, V>> asMap<K, V>() {
    return Isolate.run(() => super.asMap());
  }
}

void main(List<String> args) async {
  final fetch = Fetch(
    base: Uri.parse('https://api.gece.dev'),
    headerBuilder: () {
      return {
        'content-type': 'application/json',
      };
    },
    // timeout: Duration.zero,
    enableLogs: false,
    override: (payload, method) {
      if (payload.method == 'POST') {
        payload = payload.copyWith(body: 'SELAM');
      }

      return Isolate.run(() => method(payload));
    },
    transform: (response) {
      return IResponse.fromResponse(
        response.response,
        elapsed: response.elapsed,
        encoding: response.encoding,
        postBody: response.postBody,
      );
    },
  );

  final a = await fetch.get('info', enableLogs: true);
  final b = await a.asMap<String, dynamic>();
  print(b);
  // final r1 = await fetch.get(
  //   'https://raw.githubusercontent.com/json-iterator/test-data/master/large-file.json',
  //   cacheOptions: CacheOptions(duration: Duration(seconds: 10)),
  //   queryParams: {
  //     'foo2': 1,
  //   },
  // );

  // // final r2 = await fetch.get(
  // //   '/info',
  // //   cacheOptions: CacheOptions(duration: Duration(seconds: 10)),
  // //   queryParams: {
  // //     'foo2': 1,
  // //   },
  // // );

  // final stopwatch = Stopwatch()..start();

  // print(
  //   [
  //     '',
  //     (await r1.asJson()),
  //     stopwatch.elapsed,
  //     '',
  //     (await r1.asJson()),
  //     stopwatch.elapsed,
  //     '',
  //   ].join('\n'),
  // );
}

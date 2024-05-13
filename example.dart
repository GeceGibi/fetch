import 'dart:async';
import 'dart:isolate';

import 'package:fetch/fetch.dart';

class IResponse extends FetchResponse {
  IResponse.fromResponse(
    super.response, {
    super.elapsed,
    super.encoding,
    super.error,
  }) : super.fromResponse();

  FetchJsonData? _json;
  @override
  FutureOr<FetchJsonData> asJson() async {
    return _json ??= await Isolate.run<FetchJsonData>(() => super.asJson());
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
      return Isolate.run(() => method(payload));
    },
    transform: (response) {
      return IResponse.fromResponse(
        response,
        elapsed: response.elapsed,
        encoding: response.encoding,
        error: response.error,
      );
    },
  );

  final r1 = await fetch.get(
    'https://raw.githubusercontent.com/json-iterator/test-data/master/large-file.json',
    cacheOptions: CacheOptions(duration: Duration(seconds: 10)),
    queryParams: {
      'foo2': 1,
    },
  );

  // final r2 = await fetch.get(
  //   '/info',
  //   cacheOptions: CacheOptions(duration: Duration(seconds: 10)),
  //   queryParams: {
  //     'foo2': 1,
  //   },
  // );

  final stopwatch = Stopwatch()..start();

  print(
    [
      '',
      (await r1.asJson()),
      stopwatch.elapsed,
      '',
      (await r1.asJson()),
      stopwatch.elapsed,
      '',
    ].join('\n'),
  );
}

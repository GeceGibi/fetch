import 'dart:convert';
import 'package:test/test.dart';
import 'package:via/via.dart';

class TestPipeline extends ViaPipeline {
  bool onRequestCalled = false;
  bool onResultCalled = false;

  @override
  Future<ViaRequest> onRequest(ViaRequest request) async {
    onRequestCalled = true;
    return request;
  }

  @override
  Future<ViaResult> onResult(ViaResult result) async {
    onResultCalled = true;
    return result;
  }
}

void main() {
  late Via via;

  setUp(() {
    via = Via(
      base: Uri.parse('https://httpbin.org'),
    );
  });

  group('Via Real Request Tests', () {
    test('GET request should return ViaResult on success', () async {
      final result = await via.get('/get', queryParams: {'id': '123'});

      expect(result.statusCode, 200);
      expect(result.isSuccess, isTrue);

      final data = await result.asMap<String, dynamic>();
      expect(data['args']['id'], '123');
    });

    test('POST request should send body as JSON and receive it back', () async {
      final payload = {'name': 'Via User', 'action': 'testing'};
      final result = await via.post(
        '/post',
        jsonEncode(payload),
        headers: {'Content-Type': 'application/json'},
      );

      expect(result.statusCode, 200);
      final data = await result.asMap<String, dynamic>();
      expect(data['json'], payload);
    });

    test('POST request should send body as Form and receive it back', () async {
      final payload = {'name': 'Via User', 'action': 'testing'};
      final result = await via.post('/post', payload);

      expect(result.statusCode, 200);
      final data = await result.asMap<String, dynamic>();
      expect(data['form'], payload);
    });

    test('Pipelines should be executed in order on real request', () async {
      final pipeline = TestPipeline();
      
      via = Via(
        base: Uri.parse('https://httpbin.org'),
        pipelines: [pipeline],
      );

      await via.get('/get');

      expect(pipeline.onRequestCalled, isTrue);
      expect(pipeline.onResultCalled, isTrue);
    });

    test('ViaException should be thrown on non-existent host', () async {
      final viaBad = Via(
        base: Uri.parse('https://this-domain-does-not-exist-123.com'),
      );

      expect(
        () => viaBad.get('/test'),
        throwsA(
          isA<ViaException>().having((error) => error.type, 'type', ViaError.network),
        ),
      );
    });

    test(
      'Retry mechanism should work on real failure (using status code)',
      () async {
        via = Via(
          base: Uri.parse('https://httpbin.org'),
          retry: const ViaRetry(
            maxRetries: 2,
            retryDelay: Duration(milliseconds: 100),
          ),
        );

        // httpbin.org/status/500 returns a 500 error
        // ViaRetry's default retryIf includes status >= 500
        final result = await via.get('/status/500');
        expect(result.statusCode, 500);
      },
    );
  });

  group('ViaResult Real Mapping Tests', () {
    test('toListOf should map JSON list from real request', () async {
      // httpbin.org doesn't have a direct "return list" endpoint easily,
      // but we can use a mockable one or just test the mapping logic here
      // since the previous tests covered the network part.
      // Actually, let's use /json which returns a map, or find an endpoint that returns a list.
      // We'll use a local mock for list mapping if no easy public list API is available,
      // but user asked for REAL requests.

      // Let's use a known public API that returns a list for this specific test
      final viaPublic = Via(
        base: Uri.parse('https://jsonplaceholder.typicode.com'),
      );
      final result = await viaPublic.get('/posts');

      expect(result.statusCode, 200);
      final items = await result.toListOf((json) => json['id'] as int);

      expect(items, isNotEmpty);
      expect(items.first, isA<int>());
    });
  });
}

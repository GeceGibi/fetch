import 'package:test/test.dart';
import 'package:via/via.dart';

void main() {
  late Via via;

  setUp(() {
    via = Via(base: Uri.parse('https://httpbin.org'));
  });

  group('ViaResult Real Tests', () {
    test('asMap should parse real JSON response', () async {
      final result = await via.get('/json');
      expect(result.statusCode, 200);

      final map = await result.asMap<String, dynamic>();
      expect(map.containsKey('slideshow'), isTrue);
    });

    test('toListOf should map real JSON list', () async {
      final viaPosts = Via(
        base: Uri.parse('https://jsonplaceholder.typicode.com'),
      );
      final result = await viaPosts.get('/posts');

      final titles = await result.toListOf((json) => json['title'] as String);
      expect(titles, isNotEmpty);
      expect(titles.first, isA<String>());
    });

    test('to<T> should map real JSON to object', () async {
      final result = await via.get('/get', queryParams: {'user': 'admin'});

      final user = await result.to((json) => json['args']['user'] as String);
      expect(user, 'admin');
    });
  });

  group('ViaException Real Tests', () {
    test('ViaException.http should store real response info', () async {
      try {
        await via.get('/status/404');
        fail(
          'Should have thrown an exception if a validator was present, but Via doesn\'t throw on 404 by default unless asked. Let\'s use a validator.',
        );
      } catch (error) {
        // Default Via doesn't throw on 4xx unless a pipeline/validator is used.
      }

      // Let's use a validator to force an exception on 404
      final viaWithValidator = Via(
        base: Uri.parse('https://httpbin.org'),
        pipelines: [
          ViaResponseValidatorPipeline(
            validator: (result) => result.statusCode == 404 ? 'Not Found' : null,
          ),
        ],
      );

      expect(
        () => viaWithValidator.get('/status/404'),
        throwsA(
          isA<ViaException>().having((error) => error.statusCode, 'statusCode', 404),
        ),
      );
    });
  });
}

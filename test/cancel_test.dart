import 'package:test/test.dart';
import 'package:via/via.dart';

void main() {
  late Via via;

  setUp(() {
    via = Via(
      base: Uri.parse('https://httpbin.org'),
    );
  });

    test('CancelToken should cancel real request before sending', () async {
      final cancelToken = CancelToken()..cancel();

      expect(
        () => via.get('/get', cancelToken: cancelToken),
        throwsA(
          isA<ViaException>().having((e) => e.type, 'type', ViaError.cancelled),
        ),
      );
    });

    test('CancelToken should cancel ongoing real request', () async {
      final cancelToken = CancelToken();

      // httpbin.org/delay/n delays the response by n seconds
      final future = via.get('/delay/5', cancelToken: cancelToken);

      // Cancel after 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        cancelToken.cancel();
      });

      expect(
        () => future,
        throwsA(
          isA<ViaException>().having((e) => e.type, 'type', ViaError.cancelled),
        ),
      );
    });
}

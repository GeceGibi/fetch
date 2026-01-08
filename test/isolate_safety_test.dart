import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:via/via.dart';

void main() {
  group('Isolate Safety', () {
    test(
      'ViaResultStream.toSafeVersion() should be sendable to an isolate',
      () async {
        final request = ViaRequest(
          uri: Uri.parse('https://example.com'),
          method: ViaMethod.get,
        );

        final streamedResponse = http.StreamedResponse(
          Stream.fromIterable([
            [1, 2, 3],
          ]),
          200,
        );

        final resultStream = ViaResultStream(
          request: request,
          response: streamedResponse,
        );

        // This would normally fail if we sent resultStream directly because of ByteStream
        final safeResult = resultStream.toSafeVersion();

        final receivePort = ReceivePort();
        await Isolate.spawn(_isolateEntry, [receivePort.sendPort, safeResult]);

        final response = await receivePort.first;
        expect(response, isTrue);
      },
    );

    test('ViaLoggerPipeline should store safe versions in logs', () {
      final logger = ViaLoggerPipeline();

      final request = ViaRequest(
        uri: Uri.parse('https://example.com'),
        method: ViaMethod.get,
      );

      final streamedResponse = http.StreamedResponse(
        Stream.fromIterable([
          [1],
        ]),
        200,
      );

      final resultStream = ViaResultStream(
        request: request,
        response: streamedResponse,
      );

      // Trigger logging
      logger.onResultStream(resultStream);

      expect(logger.logs.length, 1);
      // It should still be a ViaBaseResult but NOT a ViaResultStream
      // because ViaResultStream is converted to ViaResult by toSafeVersion()
      expect(logger.logs.first, isNot(isA<ViaResultStream>()));
      expect(logger.logs.first, isA<ViaResult>());
      expect((logger.logs.first as ViaResult).statusCode, 200);
    });
  });
}

void _isolateEntry(List<dynamic> args) {
  final sendPort = args[0] as SendPort;
  // If we reached here without crash, it's sendable
  sendPort.send(true);
}

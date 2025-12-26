import 'dart:io';
import 'package:test/test.dart';
import 'package:via/via.dart';

void main() {
  late Via via;
  const videoUrl =
      'https://raw.githubusercontent.com/intel-iot-devkit/sample-videos/master/bottle-detection.mp4';

  setUp(() {
    via = Via();
  });

  test('should download a video as a stream and print chunk sizes', () async {
    final result = await via.stream(videoUrl);

    expect(result.isSuccess, isTrue);
    expect(result, isA<ViaResultStream>());

    final file = File('test_video.mp4');
    final sink = file.openWrite();

    var totalBytes = 0;
    var chunkCount = 0;

    await for (final chunk in result.stream) {
      sink.add(chunk);
      totalBytes += chunk.length;
      chunkCount++;
      print('Received chunk $chunkCount: ${chunk.length} bytes');
    }

    await sink.close();

    print('Download completed. Total bytes: $totalBytes');

    expect(totalBytes, greaterThan(0));
    expect(file.existsSync(), isTrue);

    // Clean up
    await file.delete();
    expect(file.existsSync(), isFalse);
  });
}

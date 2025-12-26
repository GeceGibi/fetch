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

  test('should listen to stream using a pipeline', () async {
    var chunkCountFromPipeline = 0;
    var totalBytesFromPipeline = 0;

    final pipeline = _StreamListenerPipeline(
      onChunk: (chunk) {
        chunkCountFromPipeline++;
        totalBytesFromPipeline += chunk.length;
      },
    );

    final result = await via.stream(videoUrl, pipelines: [pipeline]);

    expect(result.isSuccess, isTrue);

    // We must consume the stream for the pipeline to see all chunks
    int consumedBytes = 0;
    await for (final chunk in result.stream) {
      consumedBytes += chunk.length;
    }

    expect(consumedBytes, equals(totalBytesFromPipeline));
    expect(chunkCountFromPipeline, greaterThan(0));
    print(
        'Pipeline tracked $chunkCountFromPipeline chunks and $totalBytesFromPipeline bytes');
  });
}

class _StreamListenerPipeline extends ViaPipeline {
  _StreamListenerPipeline({required this.onChunk});

  final void Function(List<int> chunk) onChunk;

  @override
  Stream<List<int>> onStream(ViaResultStream result) async* {
    await for (final chunk in result.stream) {
      onChunk(chunk);
      yield chunk;
    }
  }
}

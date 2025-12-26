import 'package:via/via.dart';

/// A custom pipeline that listens to the stream and prints progress.
class ProgressPipeline extends ViaPipeline {
  @override
  Stream<List<int>> onStream(ViaResultStream result) async* {
    final total = result.response.contentLength;
    var received = 0;

    print('Pipeline: Starting stream. Total length: $total bytes');

    await for (final chunk in result.stream) {
      received += chunk.length;
      if (total != null) {
        final progress = (received / total * 100).toStringAsFixed(2);
        print('Pipeline: Progress: $progress% ($received / $total bytes)');
      } else {
        print('Pipeline: Received: $received bytes');
      }

      // Delay to simulate real-time processing
      await Future<void>.delayed(const Duration(milliseconds: 10));
      
      // Pass the chunk down the pipeline
      yield chunk;
    }
    
    print('Pipeline: Stream finished!');
  }
}

void main() async {
  final via = Via();
  const videoUrl =
      'https://raw.githubusercontent.com/intel-iot-devkit/sample-videos/master/bottle-detection.mp4';

  print('Starting stream with pipeline...\n');

  try {
    // Add the progress pipeline to this specific request
    final result = await via.stream(
      videoUrl,
      pipelines: [ProgressPipeline()],
    );

    if (result.isSuccess) {
      // We MUST listen to the stream for the pipeline to work,
      // as the pipeline's onStream is called when the stream is consumed.
      var totalReceived = 0;
      await for (final chunk in result.stream) {
        totalReceived += chunk.length;
        // We don't need to print here because the pipeline is doing it
      }
      
      print('\nMain: Finished consuming stream. Total: $totalReceived bytes');
    } else {
      print('Main: Failed to connect: ${result.statusCode}');
    }
  } catch (e) {
    print('Main: Error occurred: $e');
  }
}


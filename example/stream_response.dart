import 'package:via/via.dart';

void main() async {
  final via = Via(
    base: Uri.parse('https://test-videos.co.uk'),
  );

  print('--- Via Streaming Response Example ---');

  try {
    print('\n[1] Requesting a large response stream...');
    // The call is now a ViaCall, which can be used as a Future or a Stream.
    final call = via.get(
      '/vids/bigbuckbunny/mp4/av1/1080/Big_Buck_Bunny_1080_10s_5MB.mp4',
    );

    print('Request started! Using asByteStream() to listen to chunks.');

    print('\nListening to response stream:');
    var totalBytes = 0;

    await for (final dataChunk in call.stream) {
      totalBytes += dataChunk.length;
      print('Received chunk: ${dataChunk.length} bytes (Total: $totalBytes)');
    }

    print('\nStream finished! Total bytes: $totalBytes');

    // After the stream is finished, we can still get the result if needed.
    // However, since it's a new execution, we should be careful.
    // For this example, we just show the stream usage.

  } catch (error) {
    print('Error: $error');
  }

  print('\nExample finished!');
}


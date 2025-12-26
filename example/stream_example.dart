import 'dart:io';
import 'package:via/via.dart';

void main() async {
  final via = Via();
  const videoUrl =
      'https://raw.githubusercontent.com/intel-iot-devkit/sample-videos/master/bottle-detection.mp4';
  const fileName = 'example_video.mp4';

  print('Starting download from: $videoUrl');

  try {
    final result = await via.stream(videoUrl);

    if (result.isSuccess) {
      final file = File(fileName);
      final sink = file.openWrite();

      var totalBytes = 0;
      var chunkCount = 0;

      await for (final chunk in result.stream) {
        sink.add(chunk);
        totalBytes += chunk.length;
        chunkCount++;

        // Print the chunk size
        print('Chunk #$chunkCount received: ${chunk.length} bytes');
      }

      await sink.close();
      print('\nDownload finished!');
      print('Total size: ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB');
      print('File saved to: ${file.absolute.path}');

      // Delete the file after a short delay to demonstrate it was there
      print('\nWaiting 2 seconds before deleting the file...');
      await Future<void>.delayed(const Duration(seconds: 2));
      
      await file.delete();
      print('File deleted.');
    } else {
      print('Failed to download: ${result.statusCode}');
    }
  } catch (e) {
    print('Error occurred: $e');
  }
}


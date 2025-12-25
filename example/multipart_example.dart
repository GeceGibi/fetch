import 'dart:io';
import 'package:via/via.dart';

void main() async {
  // 1. Initialize Via with httpbin.org for testing
  final via = Via(
    base: Uri.parse('https://httpbin.org'),
  );

  print('--- Via Multipart & Methods Example ---');

  // Prepare local files for testing
  File textFile = File('example/hello.txt');
  File imageFile = File('example/dummy_image.jpg');

  // Check local directory if not in root
  if (!textFile.existsSync()) {
    textFile = File('hello.txt');
    imageFile = File('dummy_image.jpg');
  }

  if (!textFile.existsSync() || !imageFile.existsSync()) {
    print('Error: Sample files not found. Please run from project root.');
    return;
  }

  // 2. Standard POST (Body only)
  try {
    print('\n[1] Sending standard POST (JSON Body)...');
    final response = await via.post(
      '/post',
      {'name': 'John Doe', 'email': 'john@example.com'},
    );
    print('Response status: ${response.statusCode}');
  } catch (e) {
    print('Error: $e');
  }

  // 3. Multipart Request (The ONLY way to send files)
  try {
    print('\n[2] Sending Multipart request (Fields + Files)...');
    final response = await via
        .multipart(
          '/post',
          fields: {
            'description': 'Profile update',
          },
          files: {
            'image': ViaFile.fromBytes(
              imageFile.readAsBytesSync(),
              filename: 'avatar.jpg',
            ),
            'notes': ViaFile.fromString(
              textFile.readAsStringSync(),
              filename: 'notes.txt',
            ),
          },
        );
    print('Multipart status: ${response.statusCode}');
    print('Server received files: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }

  print('\nExample finished!');
}

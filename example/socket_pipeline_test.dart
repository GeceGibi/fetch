import 'dart:convert';
import 'package:via/via.dart';

/// A custom pipeline that logs events and transforms data to JSON.
class MySocketTestPipeline extends ViaSocketPipeline {
  @override
  void onOpen(ViaSocket socket) {
    print('DEBUG: [Pipeline] Connection opened. State: ${socket.readyState}');
  }

  @override
  dynamic onSend(dynamic data) {
    print('DEBUG: [Pipeline] Intercepting giden: $data');
    // Automatically wrap string into a JSON structure
    return jsonEncode({'message': data, 'timestamp': DateTime.now().toIso8601String()});
  }

  @override
  dynamic onMessage(dynamic data) {
    print('DEBUG: [Pipeline] Intercepting gelen raw: $data');
    try {
      // Automatically parse incoming JSON string
      return jsonDecode(data.toString());
    } catch (e) {
      return data;
    }
  }

  @override
  void onError(Object error) {
    print('DEBUG: [Pipeline] Error detected: $error');
  }

  @override
  void onClose(int? code, String? reason) {
    print('DEBUG: [Pipeline] Connection closed. Code: $code, Reason: $reason');
  }
}

void main() async {
  // Initialize Via with a public echo server
  final via = Via(base: Uri.parse('https://echo.websocket.org'));

  print('--- Via Socket Pipeline Test ---');

  try {
    // Connect with our custom pipeline
    final socket = await via.socket('/', pipelines: [MySocketTestPipeline()]);

    // Listen for processed messages
    socket.stream.listen((dynamic data) {
      print('RESULT: Processed message type: ${data.runtimeType}');
      print('RESULT: Data content: $data');
    });

    // Send a plain string - the pipeline will convert it to JSON
    print('\nACTION: Sending "Hello Via!"...');
    socket.send('Hello Via!');

    // Wait for the echo response
    await Future<void>.delayed(const Duration(seconds: 2));

    // Close the connection
    print('\nACTION: Closing socket...');
    await socket.close();

  } catch (e) {
    print('Test failed: $e');
  }

  print('\nTest finished!');
}


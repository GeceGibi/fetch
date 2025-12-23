import 'package:via/via.dart';

void main() async {
  // 1. Initialize Via
  final via = Via(
    base: Uri.parse(
      'https://echo.websocket.org',
    ), // A public WebSocket echo server
  );

  print('--- Via WebSocket Example ---');

  try {
    // 2. Connect to a WebSocket
    // Note: Since base is https, this will automatically connect to wss://
    print('\n[1] Connecting to WebSocket...');
    final socket = await via.socket('/');

    print('Connected! State: ${socket.readyState}');

    // 3. Listen for messages
    socket.stream.listen(
      (dynamic message) {
        print('Received from server: $message');
      },
      onError: (Object error) {
        print('Socket Error: $error');
      },
      onDone: () {
        print('Socket closed by server.');
      },
    );

    // 4. Send messages
    print('\n[2] Sending messages...');
    socket.send('Hello from Via!');
    socket.send('Testing WebSocket support...');

    // Wait a bit to receive echoes
    await Future<void>.delayed(const Duration(seconds: 2));

    // 5. Close connection
    print('\n[3] Closing connection...');
    await socket.close();
    print('Socket closed. State: ${socket.readyState}');
  } catch (e) {
    print('Connection failed: $e');
    print(
      'Note: This example requires an active internet connection to echo.websocket.org',
    );
  }

  print('\nExample finished!');
}

import 'package:via/via.dart';

void main() async {
  // 1. Initialize Via
  final via = Via(
    base: Uri.parse('https://echo.websocket.org'),
  );

  print('--- Via Socket Auto-Reconnect Test ---');

  try {
    // 2. Connect with autoReconnect enabled
    print('\n[1] Connecting with autoReconnect: true...');
    final socket = await via.socket(
      '/',
      autoReconnect: true,
      reconnectDelay: const Duration(seconds: 2),
      pipelines: [const ReconnectLogger()],
    );

    // 3. Keep the same stream listener
    socket.stream.listen((dynamic msg) {
      print('>>> Message received: $msg');
    });

    socket.send('First message');

    // 4. Simulate a connection loss by closing the raw socket manually
    // In a real scenario, this would happen due to network failure.
    print('\n[2] Simulating connection loss in 3 seconds...');
    await Future<void>.delayed(const Duration(seconds: 3));
    
    print('Closing raw socket (simulating crash)...');
    // Note: We don't call socket.close() because that's a "manual close" 
    // which stops auto-reconnect. We close the internal raw socket.
    await socket.raw?.close(); 

    // 5. Observe reconnection
    print('\n[3] Waiting for auto-reconnect (should happen in 2 seconds)...');
    await Future<void>.delayed(const Duration(seconds: 5));

    if (socket.readyState == 1) { // 1 = open
      print('Socket is back online! Sending follow-up message...');
      socket.send('Second message after reconnect');
    }

    await Future<void>.delayed(const Duration(seconds: 2));

    // 6. Manual close (stops everything)
    print('\n[4] Manual close (terminates reconnection logic)...');
    await socket.close();
    print('Final state: ${socket.readyState}');

  } catch (e) {
    print('Error: $e');
  }

  print('\nTest finished!');
}

class ReconnectLogger extends ViaSocketPipeline {
  const ReconnectLogger();

  @override
  void onOpen(ViaSocket socket) {
    print('LOG: [onOpen] Connection established.');
  }

  @override
  void onClose(int? code, String? reason) {
    print('LOG: [onClose] Connection closed. Code: $code');
  }

  @override
  void onError(Object error) {
    print('LOG: [onError] Socket error: $error');
  }
}


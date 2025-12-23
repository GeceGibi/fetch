import 'package:via/src/features/socket.dart';

/// Pipeline for WebSocket request/response and lifecycle processing.
abstract class ViaSocketPipeline {
  const ViaSocketPipeline();

  /// Called when the WebSocket connection is successfully established.
  void onOpen(ViaSocket socket) {}

  /// Called before data is sent to the server.
  ///
  /// Can return modified data to be sent.
  dynamic onSend(dynamic data) => data;

  /// Called when a message is received from the server.
  ///
  /// Can return transformed data (e.g., JSON string to Map).
  dynamic onMessage(dynamic data) => data;

  /// Called when an error occurs in the WebSocket connection or stream.
  void onError(Object error) {}

  /// Called when the WebSocket connection is closed.
  void onClose(int? code, String? reason) {}
}


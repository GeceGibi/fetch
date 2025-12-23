import 'dart:async';
import 'dart:io';

import 'package:via/src/features/pipelines/socket_pipeline.dart';

/// A simple and flexible WebSocket wrapper for Via with pipeline and auto-reconnect support.
class ViaSocket {
  ViaSocket._({
    required this.uri,
    this.protocols,
    this.headers,
    this.timeout,
    this.pipelines = const [],
    this.autoReconnect = false,
    this.reconnectDelay = const Duration(seconds: 5),
  }) : _controller = StreamController<dynamic>.broadcast() {
    for (final pipeline in pipelines) {
      pipeline.onOpen(this);
    }
  }

  /// The target URI for the connection.
  final Uri uri;

  /// Optional subprotocols to use.
  final Iterable<String>? protocols;

  /// Optional HTTP headers for the connection request.
  final Map<String, dynamic>? headers;

  /// Optional connection timeout.
  final Duration? timeout;

  /// List of pipelines applied to this socket.
  final List<ViaSocketPipeline> pipelines;

  /// Whether to automatically attempt reconnection on disconnection.
  final bool autoReconnect;

  /// Delay between reconnection attempts.
  final Duration reconnectDelay;

  WebSocket? _socket;
  final StreamController<dynamic> _controller;
  StreamSubscription<dynamic>? _subscription;
  bool _isManualClose = false;

  /// Internal factory to connect to a server.
  static Future<ViaSocket> connect(
    Uri uri, {
    Iterable<String>? protocols,
    Map<String, dynamic>? headers,
    Duration? timeout,
    List<ViaSocketPipeline> pipelines = const [],
    bool autoReconnect = false,
    Duration reconnectDelay = const Duration(seconds: 5),
  }) async {
    final viaSocket = ViaSocket._(
      uri: uri,
      protocols: protocols,
      headers: headers,
      timeout: timeout,
      pipelines: pipelines,
      autoReconnect: autoReconnect,
      reconnectDelay: reconnectDelay,
    );

    await viaSocket._connect();
    return viaSocket;
  }

  Future<void> _connect() async {
    if (_isManualClose) return;

    try {
      _socket = await WebSocket.connect(
        uri.toString(),
        protocols: protocols,
        headers: headers,
      ).timeout(timeout ?? const Duration(seconds: 30));

      for (final pipeline in pipelines) {
        pipeline.onOpen(this);
      }

      _subscription = _socket!.listen(
        (dynamic data) {
          dynamic processed = data;
          for (final pipeline in pipelines) {
            processed = pipeline.onMessage(processed);
          }
          if (!_controller.isClosed) {
            _controller.add(processed);
          }
        },
        onError: (Object error) {
          for (final pipeline in pipelines) {
            pipeline.onError(error);
          }
          if (!_controller.isClosed) {
            _controller.addError(error);
          }
          if (autoReconnect) {
            _reconnect();
          }
        },
        onDone: () {
          final code = _socket?.closeCode;
          final reason = _socket?.closeReason;
          for (final pipeline in pipelines) {
            pipeline.onClose(code, reason);
          }
          if (autoReconnect && !_isManualClose) {
            _reconnect();
          }
        },
      );
    } catch (e) {
      if (autoReconnect) {
        _reconnect();
      } else {
        rethrow;
      }
    }
  }

  void _reconnect() {
    if (_isManualClose) return;
    _subscription?.cancel();
    _socket?.close();
    Future<void>.delayed(reconnectDelay, _connect);
  }

  /// The stream of incoming messages from the server, processed through pipelines.
  /// This stream persists across reconnections.
  Stream<dynamic> get stream => _controller.stream;

  /// Sends data to the server, processed through pipelines.
  void send(dynamic data) {
    if (_socket?.readyState == WebSocket.open) {
      dynamic processedData = data;
      for (final pipeline in pipelines) {
        processedData = pipeline.onSend(processedData);
      }
      _socket!.add(processedData);
    }
  }

  /// Closes the WebSocket connection and notifies pipelines.
  Future<void> close([int? code, String? reason]) async {
    _isManualClose = true;
    _subscription?.cancel();
    await _socket?.close(code, reason);
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  /// Returns the current state of the connection.
  int get readyState => _socket?.readyState ?? WebSocket.closed;

  /// Returns the underlying [WebSocket] instance.
  WebSocket? get raw => _socket;
}

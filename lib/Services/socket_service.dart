import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';

class SocketService {

  static WebSocketChannel? _channel;

  static final List<Function(dynamic)> _listeners = [];

  static String? _token;

  static Timer? _reconnectTimer;

  /// CONNECT SOCKET
  static void connect(String token) {

  if (_channel != null) return;

  _token = token;

  print("Connecting WebSocket...");

  _channel = WebSocketChannel.connect(
    Uri.parse("${AppConstants.wsUrl}/?token=$token"),
  );

  _channel!.stream.listen(

    (message) {

      final data = jsonDecode(message);

      for (final listener in List.from(_listeners)) {
        listener(data);
      }

    },

    onDone: () {
      print("Socket closed");
      _channel = null;
      _reconnect();
    },

    onError: (err) {
      print("Socket error");
      _channel = null;
      _reconnect();
    },
  );
} /// AUTO RECONNECT
  static void _reconnect() {

    if (_token == null) return;

    _reconnectTimer?.cancel();

    _reconnectTimer = Timer(
      const Duration(seconds: 3),
      () {
        print("Reconnecting WebSocket...");
        connect(_token!);
      },
    );
  }

  /// ADD LISTENER
  static void addListener(Function(dynamic) listener) {

    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }

  }

  /// REMOVE LISTENER
  static void removeListener(Function(dynamic) listener) {

    _listeners.remove(listener);

  }

  /// DISCONNECT (LOGOUT)
  static void disconnect() {

    _reconnectTimer?.cancel();

    _channel?.sink.close();

    _channel = null;

    _listeners.clear();

  }
}
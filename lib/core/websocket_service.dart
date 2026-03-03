import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'constants.dart';

class WebSocketService {
  late WebSocketChannel _channel;

  Function(dynamic)? onMessage;

  void connect(String token) {
    _channel = WebSocketChannel.connect(
      Uri.parse("${AppConstants.wsUrl}?token=$token"),
    );

    _channel.stream.listen((message) {
      if (onMessage != null) {
        onMessage!(jsonDecode(message));
      }
    });
  }

  void disconnect() {
    _channel.sink.close();
  }
}
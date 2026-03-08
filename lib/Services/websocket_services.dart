import 'dart:convert';
import 'package:stockapp/core/constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static const String wsUrl = AppConstants.wsUrl;

  late WebSocketChannel _channel;

  Function(Map<String, dynamic>)? onData;

  void connect() {
    _channel = WebSocketChannel.connect(
      Uri.parse(wsUrl),
    );

    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (onData != null) {
        onData!(data);
      }
    });
  }

  void disconnect() {
    _channel.sink.close();
  }
}
import 'package:flutter/material.dart';
import '../core/websocket_service.dart';

class MarketProvider extends ChangeNotifier {
  final WebSocketService _ws = WebSocketService();

  Map<String, double> prices = {};
  int currentCandleIndex = 0;

  void connect(String token) {
    _ws.connect(token);

    _ws.onMessage = (data) {
      switch (data["type"]) {
        case "MARKET_TICK":
          prices = Map<String, double>.from(data["prices"]);
          currentCandleIndex = data["currentCandleIndex"];
          notifyListeners();
          break;
      }
    };
  }
}
import 'package:flutter/material.dart';
import '../services/socket_service.dart';

class MarketProvider extends ChangeNotifier {

  bool _connected = false;

  /// MARKET DATA
  Map<String, double> prices = {};
  int currentCandleIndex = 0;
  bool marketRunning = true;

  /// PORTFOLIO
  double balance = 0;
  double portfolioValue = 0;
  double netWorth = 0;
  double profitLoss = 0;
  List portfolio = [];

  /// LEADERBOARD
  List leaderboard = [];

  void connect(String token) {

    if (_connected) return;
    _connected = true;

    SocketService.connect(token);
    SocketService.addListener(_handleSocket);
  }

  void disconnect() {
    SocketService.disconnect();
    _connected = false;
  }

  void _handleSocket(dynamic data) {

    switch (data["type"]) {

      /// MARKET TICK
      case "MARKET_TICK":

        prices = Map<String, double>.from(
          (data["prices"] ?? {}).map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ),
        );

        currentCandleIndex = data["currentCandleIndex"] ?? 0;
        marketRunning = data["marketRunning"] ?? true;

        notifyListeners();
        break;

      /// PORTFOLIO UPDATE
      case "PORTFOLIO_UPDATE":

        balance = (data["balance"] ?? 0).toDouble();
        portfolioValue = (data["portfolioValue"] ?? 0).toDouble();
        netWorth = (data["netWorth"] ?? 0).toDouble();
        profitLoss = (data["profitLoss"] ?? 0).toDouble();

        portfolio = data["portfolio"] ?? [];

        notifyListeners();
        break;

      /// LEADERBOARD
      case "LEADERBOARD_UPDATE":

        leaderboard = List.from(data["leaderboard"] ?? []);

        notifyListeners();
        break;
    }
  }

  @override
  void dispose() {
    SocketService.removeListener(_handleSocket);
    super.dispose();
  }
}
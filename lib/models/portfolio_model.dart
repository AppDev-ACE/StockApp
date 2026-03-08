class PortfolioStock {
  final String symbol;
  final int quantity;
  final double avgPrice;
  final double currentPrice;
  final double value;

  PortfolioStock({
    required this.symbol,
    required this.quantity,
    required this.avgPrice,
    required this.currentPrice,
    required this.value,
  });

  factory PortfolioStock.fromJson(Map<String, dynamic> json) {
    return PortfolioStock(
      symbol: json['symbol'],
      quantity: json['quantity'],
      avgPrice: (json['avgPrice'] ?? 0).toDouble(),
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      value: (json['value'] ?? 0).toDouble(),
    );
  }

  double get profitLoss {
    return (currentPrice - avgPrice) * quantity;
  }
}
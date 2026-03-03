class PortfolioStock {
  final String symbol;
  final int quantity;
  final double avgPrice;

  PortfolioStock({
    required this.symbol,
    required this.quantity,
    required this.avgPrice,
  });

  factory PortfolioStock.fromJson(Map<String, dynamic> json) {
    return PortfolioStock(
      symbol: json['symbol'],
      quantity: json['quantity'],
      avgPrice: (json['avgPrice'] ?? 0).toDouble(),
    );
  }
}
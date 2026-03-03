// ignore: file_names
import 'package:flutter/material.dart';
import 'stock_detail_page.dart';

class Stock {
  final String name;
  final int qty;
  final double price;
  final double changePercent;

  const Stock(this.name, this.qty, this.price, this.changePercent);

  double get total => qty * price;
}

class StockPage extends StatelessWidget {
  final String token;

  const StockPage({
    super.key,
    required this.token,
  });

  final double startingPoints = 20000;

  final List<Stock> stocks = const [
    Stock("Apple", 10, 180, 1.5),
    Stock("Tesla", 5, 250, -2.1),
    Stock("Google", 2, 2800, 0.8),
    Stock("Amazon", 1, 3400, -1.2),
    Stock("Microsoft", 6, 320, 2.3),
    Stock("Nvidia", 3, 900, 4.2),
  ];

  double get investedValue =>
      stocks.fold(0.0, (sum, stock) => sum + stock.total);

  double get availableCash =>
      (startingPoints - investedValue).clamp(0, double.infinity);

  double get portfolioTotal => investedValue + availableCash;

  double get dailyChangeValue =>
      stocks.fold(0.0, (sum, s) => sum + (s.total * s.changePercent / 100));

  double get dailyChangePercent =>
      investedValue == 0 ? 0 : (dailyChangeValue / investedValue) * 100;

  Stock? get bestPerformer =>
      stocks.isEmpty
          ? null
          : stocks.reduce((a, b) =>
              a.changePercent > b.changePercent ? a : b);

  Stock? get worstPerformer =>
      stocks.isEmpty
          ? null
          : stocks.reduce((a, b) =>
              a.changePercent < b.changePercent ? a : b);

  @override
  Widget build(BuildContext context) {
    final bool isPositive = dailyChangePercent >= 0;

    final double investedRatio =
        portfolioTotal == 0 ? 0 : (investedValue / portfolioTotal).clamp(0, 1);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "ACELL Portfolio",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            const SizedBox(height: 20),

            /// Portfolio Summary
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Total Portfolio Value",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "₹ ${portfolioTotal.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 14,
                        color: isPositive
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "${dailyChangePercent >= 0 ? "+" : ""}${dailyChangePercent.toStringAsFixed(2)}% Today",
                        style: TextStyle(
                          color: isPositive
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 15),

                  LinearProgressIndicator(
                    value: investedRatio,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: Colors.greenAccent,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Invested: ₹${investedValue.toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "Available: ₹${availableCash.toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// Holdings
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: stocks.length,
              itemBuilder: (context, index) {
                final stock = stocks[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StockDetailPage(symbol: stock.name),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [

                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blueAccent,
                          child: Text(
                            stock.name[0],
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                stock.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "${stock.qty} shares",
                                style: const TextStyle(
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹ ${stock.total.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${stock.changePercent >= 0 ? "+" : ""}${stock.changePercent}%",
                              style: TextStyle(
                                color:
                                    stock.changePercent >= 0
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
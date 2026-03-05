import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/theme/app_theme.dart';
import 'stock_details_page.dart';

class StockPage extends StatefulWidget {
  final String token;

  const StockPage({super.key, required this.token});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {

  WebSocketChannel? channel;

  double balance = 0;
  double portfolioValue = 0;
  double netWorth = 0;
  double profitLoss = 0;

  List portfolio = [];

  bool connected = false;

  @override
  void initState() {
    super.initState();
    connectSocket();
  }

  void connectSocket() {

    channel = WebSocketChannel.connect(
      Uri.parse("wss://daksh-ldw4.onrender.com?token=${widget.token}")
    );

    channel!.stream.listen((message) {

      final data = jsonDecode(message);

      if (data["type"] == "PORTFOLIO_UPDATE") {

        if (!mounted) return;

        setState(() {

          balance = (data["balance"] ?? 0).toDouble();
          portfolioValue = (data["portfolioValue"] ?? 0).toDouble();
          netWorth = (data["netWorth"] ?? 0).toDouble();
          profitLoss = (data["profitLoss"] ?? 0).toDouble();

          portfolio = data["portfolio"] ?? [];

          connected = true;
        });
      }

    });
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    bool positive = profitLoss >= 0;

    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text("ACELL Portfolio"),
        centerTitle: true,
      ),

      body: connected
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// NET WORTH CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),

                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(22),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "Total Net Worth",
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "₹ ${netWorth.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [

                            Icon(
                              positive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: positive
                                  ? AppTheme.accentGreen
                                  : Colors.redAccent,
                              size: 16,
                            ),

                            const SizedBox(width: 4),

                            Text(
                              "₹${profitLoss.toStringAsFixed(0)} today",
                              style: TextStyle(
                                color: positive
                                    ? AppTheme.accentGreen
                                    : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// CASH + INVESTED
                  Row(
                    children: [

                      Expanded(
                        child: infoCard(
                          "Cash Balance",
                          balance,
                          Icons.account_balance_wallet,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: infoCard(
                          "Invested",
                          portfolioValue,
                          Icons.show_chart,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Holdings",
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  portfolio.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(
                              "No stocks purchased yet",
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: portfolio.length,

                          itemBuilder: (context, index) {

                            final stock = portfolio[index];

                            final symbol = stock["symbol"] ?? "";
                            final quantity = stock["quantity"] ?? 0;
                            final avgPrice =
                                (stock["avgPrice"] ?? 0).toDouble();

                            return GestureDetector(

                              onTap: () {

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StockDetailScreen(
                                      symbol: symbol,
                                      price: avgPrice,
                                      token: widget.token,
                                      quantity: quantity,
                                      avgPrice: avgPrice,
                                    ),
                                  ),
                                );

                              },

                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),

                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                ),

                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,

                                  children: [

                                    Row(
                                      children: [

                                        CircleAvatar(
                                          backgroundColor: AppTheme.accentBlue,
                                          child: Text(
                                            symbol.isNotEmpty
                                                ? symbol[0]
                                                : "?",
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,

                                          children: [

                                            Text(
                                              symbol,
                                              style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),

                                            Text(
                                              "$quantity shares",
                                              style: const TextStyle(
                                                  color: AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    Text(
                                      "Avg ₹${avgPrice.toStringAsFixed(1)}",
                                      style: const TextStyle(
                                        color: AppTheme.accentGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget infoCard(String title, double value, IconData icon) {

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              const Icon(Icons.circle, color: AppTheme.textSecondary, size: 10),

              const SizedBox(width: 6),

              Text(
                title,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            "₹ ${value.toStringAsFixed(0)}",
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
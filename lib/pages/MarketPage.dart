import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stockapp/core/constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/theme/app_theme.dart';
import 'stock_details_page.dart';

class MarketPage extends StatefulWidget {

  final String token;

  const MarketPage({
    super.key,
    required this.token,
  });

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {

  WebSocketChannel? channel;

  Map<String, dynamic> prices = {};
  Map<String, dynamic> filteredPrices = {};

  bool connected = false;

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    connectSocket();
  }

  void connectSocket() {

    channel = WebSocketChannel.connect(
      Uri.parse("${AppConstants.wsUrl}?token=${widget.token}")
    );

    channel!.stream.listen((message) {

      final data = jsonDecode(message);

      if (data["type"] == "MARKET_TICK") {

        final updatedPrices =
            Map<String, dynamic>.from(data["prices"]);

        if (!mounted) return;

        setState(() {

          prices = updatedPrices;

          if (searchController.text.isEmpty) {
            filteredPrices = prices;
          } else {
            applyFilter(searchController.text);
          }

          connected = true;
        });
      }

    }, onError: (error) {

      debugPrint("WebSocket error: $error");

    }, onDone: () {

      debugPrint("WebSocket closed");

    });
  }

  void applyFilter(String query) {

    final filtered = prices.entries.where((entry) {

      return entry.key
          .toLowerCase()
          .contains(query.toLowerCase());

    });

    filteredPrices = {
      for (var e in filtered) e.key: e.value
    };
  }

  @override
  void dispose() {

    channel?.sink.close();
    searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final symbols = filteredPrices.keys.toList();

    return Scaffold(
      backgroundColor: AppTheme.background,

      body: connected
          ? Column(
              children: [

                const SizedBox(height: 45),

                /// SEARCH BAR
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),

                  child: TextField(
                    controller: searchController,

                    onChanged: (value) {

                      setState(() {
                        applyFilter(value);
                      });

                    },

                    style:
                        const TextStyle(color: AppTheme.textPrimary),

                    decoration: InputDecoration(
                      hintText: "Search stock...",
                      hintStyle: const TextStyle(
                          color: AppTheme.textSecondary),

                      prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.textSecondary),

                      filled: true,
                      fillColor: AppTheme.surface,

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// STOCK LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: symbols.length,

                    itemBuilder: (context, index) {

                      final symbol = symbols[index];

                      final price =
                          (filteredPrices[symbol] ?? 0)
                              .toDouble();

                      return GestureDetector(

                        onTap: () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StockDetailScreen(
                                symbol: symbol,
                                price: price,
                                token: widget.token,
                              ),
                            ),
                          );

                        },

                        child: Container(
                          margin:
                              const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8),

                          padding:
                              const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius:
                                BorderRadius.circular(
                                    16),
                          ),

                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,

                            children: [

                              /// SYMBOL
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  Text(
                                    symbol,
                                    style:
                                        const TextStyle(
                                      color:
                                          AppTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                      height: 3),

                                  const Text(
                                    "Live Market",
                                    style: TextStyle(
                                      color:
                                          AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  )
                                ],
                              ),

                              /// PRICE
                              Row(
                                children: [

                                  Text(
                                    "₹${price.toStringAsFixed(2)}",
                                    style:
                                        const TextStyle(
                                      color: AppTheme
                                          .accentGreen,
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                      width: 12),

                                  const Icon(
                                    Icons
                                        .show_chart_rounded,
                                    color: AppTheme
                                        .accentBlue,
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
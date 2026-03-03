import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MarketPage extends StatefulWidget {
  final String token;

  const MarketPage({super.key, required this.token});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  late WebSocketChannel channel;

  Map<String, dynamic> prices = {};
  Map<String, dynamic> filteredPrices = {};
  bool isConnected = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  void connectWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse("ws://localhost:3000?token=${widget.token}"),
    );

    channel.stream.listen(
      (message) {
        final data = jsonDecode(message);

        if (data["type"] == "MARKET_TICK") {
          final updatedPrices =
              Map<String, dynamic>.from(data["prices"]);

          setState(() {
            prices = updatedPrices;

            // Maintain search state properly
            if (searchController.text.isNotEmpty) {
              _applyFilter(searchController.text);
            } else {
              filteredPrices = prices;
            }

            isConnected = true;
          });
        }
      },
      onError: (error) {
        print("WebSocket Error: $error");
      },
      onDone: () {
        print("WebSocket Closed");
      },
    );
  }

  void _applyFilter(String query) {
    final filtered = prices.entries
        .where((entry) =>
            entry.key.toLowerCase().contains(query.toLowerCase()))
        .fold<Map<String, dynamic>>({}, (map, entry) {
      map[entry.key] = entry.value;
      return map;
    });

    filteredPrices = filtered;
  }

  @override
  void dispose() {
    channel.sink.close();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbols = filteredPrices.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: isConnected
          ? Column(
              children: [
                const SizedBox(height: 40),

                /// SEARCH BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        _applyFilter(value);
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search stock...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF161B22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                      final price = filteredPrices[symbol];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            /// STOCK NAME
                            Text(
                              symbol,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Row(
                              children: [
                                /// PRICE
                                Text(
                                  "₹$price",
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                /// GRAPH ICON
                                IconButton(
                                  icon: const Icon(
                                    Icons.show_chart,
                                    color: Colors.blueAccent,
                                  ),
                                  onPressed: () {
                                    print("Open chart for $symbol");
                                  },
                                )
                              ],
                            )
                          ],
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/market_provider.dart';
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

  Map<String, double> filteredPrices = {};

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    /// connect socket via provider
    // Future.microtask(() {
    //   context.read<MarketProvider>().connect(widget.token);
    // });
  }

  void applyFilter(String query, Map<String, double> prices) {

    if (query.isEmpty) {
      filteredPrices = prices;
      return;
    }

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

    searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final prices = context.select((MarketProvider m) => m.prices);
final marketRunning = context.select((MarketProvider m) => m.marketRunning);

    

  if (searchController.text.isEmpty) {
  filteredPrices = prices;
} else {
  applyFilter(searchController.text, prices);
}

    final symbols = filteredPrices.keys.toList();

    return Scaffold(
      backgroundColor: AppTheme.background,

      body: prices.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [

                const SizedBox(height: 45),

                /// MARKET STATUS
                if (!marketRunning)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    color: Colors.redAccent,
                    child: const Center(
                      child: Text(
                        "MARKET CLOSED",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                /// SEARCH BAR
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),

                  child: TextField(
                    controller: searchController,

                    onChanged: (value) {

                      setState(() {
                        applyFilter(value, prices);
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
                                marketRunning: marketRunning,
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
            ),
    );
  }
}
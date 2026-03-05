import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  final double price;
  final String token;

  final int? quantity;
  final double? avgPrice;

  const StockDetailScreen({
    super.key,
    required this.symbol,
    required this.price,
    required this.token,
    this.quantity,
    this.avgPrice,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {

  List<CandlestickSpot> candles = [];

  WebSocketChannel? channel;

  int lastIndex = 0;
  int maxCandles = 40;

  double currentPrice = 0;

  double minY = 0;
  double maxY = 0;

  bool loading = true;
  bool placingOrder = false;

  TextEditingController qtyController = TextEditingController();

  int quantity = 0;
  double avgPrice = 0;

  @override
  void initState() {
    super.initState();

    currentPrice = widget.price;

    quantity = widget.quantity ?? 0;
    avgPrice = widget.avgPrice ?? 0;

    loadInitialCandles();
    connectLiveFeed();
  }

  /// LOAD INITIAL CANDLES
  Future<void> loadInitialCandles() async {

    try {

      final res = await http.get(
        Uri.parse(
          "https://daksh-ldw4.onrender.com/candles?symbol=${widget.symbol}&range=1H"
        ),
      );

      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);

      final raw = data["candles"];

      lastIndex = data["currentIndex"];

      final trimmed =
          raw.length > maxCandles ? raw.sublist(raw.length - maxCandles) : raw;

      candles.clear();

      for (int i = 0; i < trimmed.length; i++) {

        final c = trimmed[i];

        candles.add(
          CandlestickSpot(
            x: i.toDouble(),
            open: (c["open"]).toDouble(),
            high: (c["high"]).toDouble(),
            low: (c["low"]).toDouble(),
            close: (c["close"]).toDouble(),
          ),
        );
      }

      updateChartRange();

      setState(() {
        loading = false;
      });

    } catch (e) {}
  }

  /// AUTO SCALE CHART
  void updateChartRange() {

    if (candles.isEmpty) return;

    double localMin =
        candles.map((c) => c.low).reduce(min);

    double localMax =
        candles.map((c) => c.high).reduce(max);

    minY = localMin * 0.99;
    maxY = localMax * 1.01;
  }

  /// LIVE FEED
void connectLiveFeed() {

  void connect() {

    channel = WebSocketChannel.connect(
      Uri.parse("wss://daksh-ldw4.onrender.com?token=${widget.token}"),
    );

    channel!.stream.listen(

      (message) async {

        final data = jsonDecode(message);

        if (data["type"] == "MARKET_TICK") {

          final prices = Map<String, dynamic>.from(data["prices"]);

          if (prices.containsKey(widget.symbol)) {
            setState(() {
              currentPrice = prices[widget.symbol].toDouble();
            });
          }

          int newIndex = data["currentCandleIndex"];

          if (newIndex > lastIndex) {

            lastIndex = newIndex;

            final res = await http.get(
              Uri.parse(
                "https://daksh-ldw4.onrender.com/candles?symbol=${widget.symbol}"
              ),
            );

            if (res.statusCode != 200) return;

            final json = jsonDecode(res.body);
            final latest = json["candles"].last;

            final candle = CandlestickSpot(
              x: candles.length.toDouble(),
              open: (latest["open"]).toDouble(),
              high: (latest["high"]).toDouble(),
              low: (latest["low"]).toDouble(),
              close: (latest["close"]).toDouble(),
            );

            setState(() {

              candles.add(candle);

              if (candles.length > maxCandles) {

                candles.removeAt(0);

                for (int i = 0; i < candles.length; i++) {
                  candles[i] = CandlestickSpot(
                    x: i.toDouble(),
                    open: candles[i].open,
                    high: candles[i].high,
                    low: candles[i].low,
                    close: candles[i].close,
                  );
                }
              }

              updateChartRange();
            });
          }
        }
      },

      onDone: () {

        print("WebSocket disconnected... reconnecting");

        Future.delayed(const Duration(seconds: 3), connect);
      },

      onError: (error) {

        print("WebSocket error: $error");

        Future.delayed(const Duration(seconds: 3), connect);
      },
    );
  }

  connect();
}
  /// BUY STOCK
  Future<void> buyStock() async {

    int qty = int.tryParse(qtyController.text) ?? 0;

    if (qty <= 0) {
      showSnack("Invalid quantity");
      return;
    }

    setState(() => placingOrder = true);

    try {

      final res = await http.post(
        Uri.parse("https://daksh-ldw4.onrender.com/buy"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": widget.token
        },
        body: jsonEncode({
          "symbol": widget.symbol,
          "quantity": qty
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {

        showSnack(data["error"] ?? "Buy failed");

      } else {

        setState(() {

          quantity += qty;

          avgPrice = ((avgPrice * (quantity - qty)) +
                  (currentPrice * qty)) /
              quantity;
        });

        showSnack("Bought $qty shares");
      }

    } catch (e) {
      showSnack("$qty");
    }

    setState(() => placingOrder = false);
  }

  /// SELL STOCK
  Future<void> sellStock() async {

    int qty = int.tryParse(qtyController.text) ?? 0;

    if (qty <= 0) {
      showSnack("Invalid quantity");
      return;
    }

    setState(() => placingOrder = true);

    try {

      final res = await http.post(
        Uri.parse("https://daksh-ldw4.onrender.com/sell"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": widget.token
        },
        body: jsonEncode({
          "symbol": widget.symbol,
          "quantity": qty
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {

        showSnack(data["error"] ?? "Sell failed");

      } else {

        setState(() {

          quantity -= qty;

          if (quantity < 0) quantity = 0;
        });

        showSnack("Sold $qty shares");
      }

    } catch (e) {
      showSnack("$e");
    }

    setState(() => placingOrder = false);
  }

  void showSnack(String msg) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg))
    );
  }

  @override
  void dispose() {
    channel?.sink.close();
    qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    double currentValue =
        quantity * currentPrice;

    double pnl =
        (currentPrice - avgPrice) * quantity;

    bool positive = pnl >= 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.symbol),
      ),

      body: Column(
        children: [

          const SizedBox(height: 10),

          /// LIVE PRICE
          Text(
            "₹ ${currentPrice.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),

          const SizedBox(height: 10),

          /// USER POSITION
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Column(
              children: [

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [

                    info("Shares", quantity.toString()),
                    info("Avg", "₹${avgPrice.toStringAsFixed(2)}"),
                    info("Value", "₹${currentValue.toStringAsFixed(0)}"),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  "P/L ₹${pnl.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: positive
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// CANDLE CHART
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16),

                    child: CandlestickChart(
                      CandlestickChartData(
                        candlestickSpots: candles,
                        minY: minY,
                        maxY: maxY,

                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),

                        borderData: FlBorderData(show: false),

                        titlesData: FlTitlesData(show: false),
                      ),
                    ),
                  ),
          ),

          /// TRADE PANEL
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF161B22),

            child: Column(
              children: [

                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),

                  decoration: InputDecoration(
                    hintText: "Enter quantity",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [

                    Expanded(
                      child: ElevatedButton(
                        onPressed: placingOrder ? null : buyStock,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                        ),

                        child: const Text("BUY"),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: placingOrder ? null : sellStock,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),

                        child: const Text("SELL"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget info(String title, String value) {

    return Column(
      children: [

        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
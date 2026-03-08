import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:stockapp/core/constants.dart';
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
  int maxCandles = 200;

  double currentPrice = 0;
  double previousPrice = 0;

  double minY = 0;
  double maxY = 0;

  bool loading = true;
  bool placingOrder = false;

  final TransformationController chartTransform =
      TransformationController();
  final ScrollController chartScroll = ScrollController();

  TextEditingController qtyController = TextEditingController();

  int quantity = 0;
  double avgPrice = 0;

  CandlestickSpot? selectedCandle;

  @override
  void initState() {
    super.initState();

    currentPrice = widget.price;
    previousPrice = widget.price;

    quantity = widget.quantity ?? 0;
    avgPrice = widget.avgPrice ?? 0;

    loadInitialCandles();
    connectLiveFeed();
  }

  /// AUTO SCROLL TO LATEST
void scrollToLatest() {
  if (chartScroll.hasClients) {
    chartScroll.animateTo(
      chartScroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}

 /// LOAD INITIAL CANDLES
  Future<void> loadInitialCandles() async {

    try {

      final res = await http.get(
        Uri.parse(
            "${AppConstants.baseUrl}/candles?symbol=${widget.symbol}&range=1H"
        ),
      );

      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);

      final raw = data["candles"];

      lastIndex = data["currentIndex"];

      final trimmed =
      raw.length > maxCandles ? raw.sublist(raw.length - maxCandles) : raw;

      candles.clear();

      int startIndex = max(0, lastIndex - trimmed.length + 1).floor();

      for (int i = 0; i < trimmed.length; i++) {

        final c = trimmed[i];

        candles.add(
          CandlestickSpot(
            x: (startIndex + i).toDouble(),
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

      Future.delayed(const Duration(milliseconds: 100), () {
        //double candleWidth = MediaQuery.of(context).size.width / 30;
        scrollToLatest();
      });

    } catch (_) {}
  }

  /// AUTO SCALE CHART
  void updateChartRange() {

  if (candles.isEmpty) return;

  double localMin = candles.map((c) => c.low).reduce(min);
  double localMax = candles.map((c) => c.high).reduce(max);

  double range = localMax - localMin;

  if (range < 1) {
    range = 1;
  }

  double padding = range * 0.10;

  minY = localMin - padding;
  maxY = localMax + padding;
}

 /// UPDATE CURRENT CANDLE
  void updateCurrentCandle(double price) {

    if (candles.isEmpty) return;

    final last = candles.last;

    candles[candles.length - 1] = CandlestickSpot(
      x: last.x,
      open: last.open,
      high: max(last.high, price),
      low: min(last.low, price),
      close: price,
    );
  }

  /// LIVE FEED
  void connectLiveFeed() {

    void connect() {

      channel = WebSocketChannel.connect(
        Uri.parse("${AppConstants.wsUrl}?token=${widget.token}"),
      );

      channel!.stream.listen(

            (message) async {

          final data = jsonDecode(message);

          if (data["type"] == "MARKET_TICK") {

            final prices = Map<String, dynamic>.from(data["prices"]);

            if (prices.containsKey(widget.symbol)) {

              double price = prices[widget.symbol].toDouble();

              setState(() {
                previousPrice = currentPrice;
                currentPrice = price;
                updateCurrentCandle(price);
              });
            }

            int newIndex = data["currentCandleIndex"];

            if (newIndex > lastIndex) {

              lastIndex = newIndex;

              final res = await http.get(
                Uri.parse(
                    "${AppConstants.baseUrl}/candles?symbol=${widget.symbol}"
                ),
              );

              if (res.statusCode != 200) return;

              final json = jsonDecode(res.body);
              final latest = json["candles"].last;

              final candle = CandlestickSpot(
                x: lastIndex.toDouble(),
                open: (latest["open"]).toDouble(),
                high: (latest["high"]).toDouble(),
                low: (latest["low"]).toDouble(),
                close: (latest["close"]).toDouble(),
              );

              setState(() {

                candles.add(candle);

                if (candles.length > maxCandles) {
                  candles.removeAt(0);
                }
                selectedCandle = null;
                updateChartRange();
              });

              Future.delayed(const Duration(milliseconds: 60), () {

                //double candleWidth =
                   // MediaQuery.of(context).size.width / 30;

                scrollToLatest();

              });
            }
          }
        },

        onDone: () {
          Future.delayed(const Duration(seconds: 3), connect);
        },

        onError: (_) {
          Future.delayed(const Duration(seconds: 3), connect);
        },
      );
    }

    connect();
  }

  /// BUY
  Future<void> buyStock() async {

    int qty = int.tryParse(qtyController.text) ?? 0;

    if (qty <= 0) {
      showSnack("Invalid quantity");
      return;
    }

    setState(() => placingOrder = true);

    try {

      final res = await http.post(
        Uri.parse("${AppConstants.baseUrl}/buy"),
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

          avgPrice =
              ((avgPrice * (quantity - qty)) + (currentPrice * qty)) /
                  quantity;
        });

        showSnack("Bought $qty shares");
      }

    } catch (_) {
      showSnack("Buy failed");
    }

    setState(() => placingOrder = false);
  }

  /// SELL
  Future<void> sellStock() async {

    int qty = int.tryParse(qtyController.text) ?? 0;

    if (qty <= 0) {
      showSnack("Invalid quantity");
      return;
    }

    setState(() => placingOrder = true);

    try {

      final res = await http.post(
        Uri.parse("${AppConstants.baseUrl}/sell"),
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

    } catch (_) {
      showSnack("Sell failed");
    }

    setState(() => placingOrder = false);
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    channel?.sink.close();
    qtyController.dispose();
    chartScroll.dispose();
    chartTransform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    double currentValue = quantity * currentPrice;
    double pnl = (currentPrice - avgPrice) * quantity;

    bool positive = pnl >= 0;

    bool marketUp = currentPrice >= previousPrice;

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

          /// PRICE
          Text(
            "₹ ${currentPrice.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: marketUp
                  ? Colors.greenAccent
                  : Colors.redAccent,
            ),
          ),

          const SizedBox(height: 10),

          /// POSITION
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

        Builder(
  builder: (_) {

    if (candles.isEmpty) return const SizedBox();

    final display = selectedCandle ?? candles.last;

    bool bullish = display.close >= display.open;
    Color color = bullish ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Expanded(child: ohlcFull("Open", display.open, color)),

          Expanded(child: ohlcFull("High", display.high, color)),

          Expanded(child: ohlcFull("Low", display.low, color)),

          Expanded(child: ohlcFull("Close", display.close, color)),

        ],
      ),
    );
  },
),


//chArt
        Expanded(
          flex: 3,
  child: loading
      ? const Center(child: CircularProgressIndicator())
      : Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {

              const double candleWidth = 12; // candle thickness

              double chartWidth =
                  max(candles.length * candleWidth, constraints.maxWidth);

            return  SingleChildScrollView(
    controller: chartScroll,
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: chartWidth,
      child: CandlestickChart(
        CandlestickChartData(
          candlestickSpots: candles,
          minY: minY,
          maxY: maxY,

candlestickTouchData: CandlestickTouchData(
  enabled: true,
  handleBuiltInTouches: false,
  touchCallback: (event, response) {

    if (event is FlTapUpEvent ||
        event is FlLongPressEnd ||
        event is FlPanEndEvent) {

      setState(() {
        selectedCandle = null;
      });

      return;
    }

    if (response != null && response.touchedSpot != null) {
      setState(() {
        selectedCandle = response.touchedSpot!.spot;
      });
    }
  },
),

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 5,
          ),

          borderData: FlBorderData(show: false),

          titlesData: FlTitlesData(show: false),

          clipData: FlClipData.none(),
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
    ),
  );

           
            },
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
                    hintStyle:
                    const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor:
                    Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [

                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                        placingOrder ? null : buyStock,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Colors.greenAccent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("BUY"),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                        placingOrder ? null : sellStock,
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

  Widget ohlc(String label, double value) {

  if (candles.isEmpty) {
    return const SizedBox();
  }

  final display = selectedCandle ?? candles.last;

  bool bullish = display.close >= display.open;

  Color color = bullish ? Colors.greenAccent : Colors.redAccent;

  return Text(
    "$label: ${value.toStringAsFixed(2)}",
    style: TextStyle(
      color: color,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );
}

Widget ohlcFull(String label, double value, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [

      Text(
        label,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
        ),
      ),

      const SizedBox(height: 2),

      Text(
        value.toStringAsFixed(2),
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

    ],
  );
}
}
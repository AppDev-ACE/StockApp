import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

class CandleData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  CandleData(this.time, this.open, this.high, this.low, this.close);

  factory CandleData.fromJson(Map<String, dynamic> json) {
    return CandleData(
      DateTime.parse(json['time']),
      json['open'].toDouble(),
      json['high'].toDouble(),
      json['low'].toDouble(),
      json['close'].toDouble(),
    );
  }
}

class StockDetailPage extends StatefulWidget {
  final String symbol;

  const StockDetailPage({super.key, required this.symbol});

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {

  List<CandleData> candles = [];
  bool isLoading = true;
  String selectedRange = "1D";

  @override
  void initState() {
    super.initState();
    fetchCandles();
  }

  Future<void> fetchCandles() async {
    setState(() => isLoading = true);

    final response = await http.get(
      Uri.parse(
          "https://daksh-ldw4.onrender.com/candles?symbol=${widget.symbol}&range=$selectedRange"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      candles = data.map((e) => CandleData.fromJson(e)).toList();
    }

    setState(() => isLoading = false);
  }

  double get currentPrice =>
      candles.isNotEmpty ? candles.last.close : 0;

  double get priceChange =>
      candles.length > 1
          ? currentPrice - candles.first.open
          : 0;

  double get percentChange =>
      candles.length > 1
          ? (priceChange / candles.first.open) * 100
          : 0;

  @override
  Widget build(BuildContext context) {

    final bool isPositive = percentChange >= 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.symbol,
          style: const TextStyle(color: Colors.white),
        ),
      ),

      body: Column(
        children: [

          const SizedBox(height: 20),

          /// PRICE HEADER
          Column(
            children: [
              Text(
                "₹ ${currentPrice.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "${priceChange.toStringAsFixed(2)} (${percentChange.toStringAsFixed(2)}%)",
                style: TextStyle(
                  color: isPositive
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// TIME RANGE SWITCHER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ["1D", "1W", "1M", "1Y"].map((range) {
              final isSelected = selectedRange == range;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedRange = range;
                  });
                  fetchCandles();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.greenAccent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    range,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          /// CANDLESTICK CHART
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator())
                : SfCartesianChart(
                    backgroundColor: Colors.transparent,
                    zoomPanBehavior:
                        ZoomPanBehavior(enablePinching: true),
                    tooltipBehavior:
                        TooltipBehavior(enable: true),
                    series: <CandleSeries>[
                      CandleSeries<CandleData, DateTime>(
                        dataSource: candles,
                        xValueMapper:
                            (CandleData data, _) => data.time,
                        lowValueMapper:
                            (CandleData data, _) => data.low,
                        highValueMapper:
                            (CandleData data, _) => data.high,
                        openValueMapper:
                            (CandleData data, _) => data.open,
                        closeValueMapper:
                            (CandleData data, _) => data.close,
                        bullColor: Colors.greenAccent,
                        bearColor: Colors.redAccent,
                      )
                    ],
                  ),
          ),

          /// BUY SELL
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.greenAccent),
                    onPressed: () {},
                    child: const Text("BUY"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.redAccent),
                    onPressed: () {},
                    child: const Text("SELL"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
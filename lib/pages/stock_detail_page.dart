import 'package:flutter/material.dart';
import 'home_page.dart';

class StockDetailPage extends StatefulWidget {
  final Stock stock;

  const StockDetailPage({super.key, required this.stock});

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  final TextEditingController controller = TextEditingController();

  void sellStock() {
    int sellQty = int.tryParse(controller.text) ?? 0;

    if (sellQty <= 0) {
      showMessage("Enter valid quantity");
      return;
    }

    if (sellQty > widget.stock.qty) {
      showMessage("You don't have that many shares!");
      return;
    }

    // reduce quantity
    widget.stock.qty -= sellQty;

    showMessage(
        "Sold $sellQty shares for ₹${(sellQty * widget.stock.price).toStringAsFixed(0)}");

    // return updated stock back
    Navigator.pop(context, widget.stock);
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0d0d0d),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Selling Page"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            buildInfo("Company", widget.stock.name),
            buildInfo("Stocks Owned", "${widget.stock.qty}"),
            buildInfo("Price per Stock", "₹${widget.stock.price}"),
            buildInfo(
              "Total Value",
              "₹${widget.stock.total.toStringAsFixed(0)}",
            ),

            const SizedBox(height: 20),

            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter shares to sell",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xff1a1a1a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sellStock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "SELL",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfo(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xff1a1a1a),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

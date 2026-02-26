import 'package:flutter/material.dart';

class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Market"),
        backgroundColor: Colors.black,
      ),

      body: const Center(
        child: Text("Market Page", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'stock_detail_page.dart';

class Stock {
  final String name;
  int qty; 
  final double price;

  Stock(this.name, this.qty, this.price);

  double get total => qty * price;
}

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {

  final List<Stock> stocks = [
    Stock("Apple", 10, 180),
    Stock("Tesla", 5, 250),
    Stock("Google", 2, 2800),
    Stock("Amazon", 1, 3400),
    Stock("Microsoft", 6, 320),
    Stock("Nvidia", 3, 900),
  ];

  double get portfolioTotal =>
      stocks.fold(0, (sum, stock) => sum + stock.total);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0d0d0d),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Stock", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),

      body: Column(
        children: [
          const SizedBox(height: 20),

          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
                padding: const EdgeInsets.all(60),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff00c6ff),
                      Color.fromARGB(255, 58, 130, 255),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              Column(
                children: [
                  const Text(
                    "Total",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  Text(
                    "₹${portfolioTotal.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 30),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: .9,
              ),

              itemCount: stocks.length,

              itemBuilder: (context, index) {
                final stock = stocks[index];

                return GestureDetector(
                  onTap: () async {
                    final updatedStock = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StockDetailPage(stock: stock),
                      ),
                    );

                    if (updatedStock != null) {
                      setState(() {
                        stock.qty = updatedStock.qty;
                      });
                    }
                  },

                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff1a1a1a),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    padding: const EdgeInsets.all(16),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blueAccent,
                          child: Text(
                            stock.name[0],
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          stock.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "${stock.qty} shares",
                          style: const TextStyle(color: Colors.grey),
                        ),

                        const Spacer(),

                        Text(
                          "₹${stock.total.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

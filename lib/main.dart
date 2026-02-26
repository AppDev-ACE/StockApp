import 'package:flutter/material.dart';

import 'package:stockapp/pages/HomePage.dart';
import 'package:stockapp/pages/MarketPage.dart';
import 'package:stockapp/pages/TutorialPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  final pages = [StockPage(), MarketPage(), TutorialPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,

        selectedItemColor: Colors.blue,

        unselectedItemColor: Colors.grey,

        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),

          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: "Market",
          ),

          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Tutorial"),
        ],
      ),
    );
  }
}

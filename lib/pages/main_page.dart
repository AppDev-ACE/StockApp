import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'leaderboard_page.dart';
import 'MarketPage.dart';

class MainPage extends StatefulWidget {
  final String token;

  const MainPage({
    super.key,
    required this.token,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final List<Widget> pages;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    pages = [
      StockPage(token: widget.token),
      MarketPage(token: widget.token),
      LeaderboardPage(token: widget.token),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: "Portfolio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart),
            label: "Market",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard),
            label: "Leaderboard",
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'HomePage.dart';
//import 'leaderboard_page.dart';
import 'MarketPage.dart';
import '../services/socket_service.dart';
import 'package:provider/provider.dart';
import '../provider/market_provider.dart';

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

  int currentIndex = 0;
  late final List<Widget> pages;
  //late final MarketProvider marketProvider;

@override
void initState() {
  super.initState();

  Future.microtask(() {
    final marketProvider =
        Provider.of<MarketProvider>(context, listen: false);

    marketProvider.connect(widget.token);
  });

  pages = [
    StockPage(token: widget.token),
    MarketPage(token: widget.token),
  ];
}

 void changeTab(int index) {
    if (index == currentIndex) return;

    setState(() {
      currentIndex = index;
    });
  }

@override
Widget build(BuildContext context) {

  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,

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
      onTap: changeTab,

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
      ],
    ),
  );
}
}

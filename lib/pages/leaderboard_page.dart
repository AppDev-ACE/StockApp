import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:web_socket_channel/web_socket_channel.dart';
//import 'package:shared_preferences/shared_preferences.dart';
//import '../core/constants.dart';
import '../services/socket_service.dart';

class LeaderboardPage extends StatefulWidget {
  final String token;
  

  const LeaderboardPage({
    super.key,
    required this.token,
  });

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<dynamic> leaderboard = [];
  bool loading = true;
  //WebSocketChannel? channel;

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

void connectWebSocket() {

  SocketService.addListener(_handleSocket);

}

void _handleSocket(dynamic data) {

  if (data["type"] == "LEADERBOARD_UPDATE") {

    if (!mounted) return;

    setState(() {
      leaderboard = data["leaderboard"] ?? [];
      loading = false;
    });

  }

}

  @override
  void dispose() {
    SocketService.removeListener(_handleSocket);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Leaderboard")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final user = leaderboard[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "#${index + 1}",
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            user["username"],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "₹ ${user["netWorth"]}",
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
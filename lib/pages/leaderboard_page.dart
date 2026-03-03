import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

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
  WebSocketChannel? channel;

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  Future<void> connectWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) return;

    channel = WebSocketChannel.connect(
      Uri.parse("${AppConstants.wsUrl}?token=$token"),
    );

    channel!.stream.listen((message) {
      final data = jsonDecode(message);

      if (data["type"] == "LEADERBOARD_UPDATE") {
        setState(() {
          leaderboard = data["leaderboard"];
        });
      }
    });
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(title: const Text("Leaderboard")),
      body: leaderboard.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
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
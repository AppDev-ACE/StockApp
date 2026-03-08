import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/socket_service.dart';
import 'login_screen.dart';

class AdminPage extends StatefulWidget {
  final String token;

  const AdminPage({super.key, required this.token});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {

  bool marketRunning = true;

  List leaderboard = [];

  @override
  void initState() {
    super.initState();
    connectSocket();
    loadLeaderboard();
  }

  /// LOAD INITIAL LEADERBOARD
  Future<void> loadLeaderboard() async {

    try {

      final res = await http.get(
        Uri.parse("${AppConstants.baseUrl}/admin/leaderboard"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);

      if (!mounted) return;

      
        setState(() {
  leaderboard = List.from(data);
});
      

    } catch (_) {}
  }

  /// WEBSOCKET
  void connectSocket() {

  SocketService.addListener(_handleSocket);

}

void _handleSocket(dynamic data){

  if (!mounted) return;

  /// MARKET STATUS
  if (data["type"] == "MARKET_TICK") {

    setState(() {
      marketRunning = data["marketRunning"] ?? true;
    });

  }

  /// LIVE LEADERBOARD
  if (data["type"] == "LEADERBOARD_UPDATE") {

    setState(() {
      leaderboard = List.from(data["leaderboard"] ?? []);
    });

  }

}
 /// STOP MARKET
  Future stopMarket() async {

    final res = await http.post(
      Uri.parse("${AppConstants.baseUrl}/admin/stop-market"),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );

    if (res.statusCode == 200) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Market stopped")),
      );

    }

  }

  /// START MARKET
  Future startMarket() async {

    final res = await http.post(
      Uri.parse("${AppConstants.baseUrl}/admin/start-market"),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );

    if (res.statusCode == 200) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Market started")),
      );

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

      appBar: AppBar(
        title: const Text("Admin Panel"),
        actions: [

    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: logout,
    ),

  ],
      ),

      body: Column(

        children: [

          /// MARKET STATUS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: marketRunning ? Colors.green : Colors.red,
            child: Center(
              child: Text(
                marketRunning
                    ? "MARKET OPEN"
                    : "MARKET CLOSED",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// START / STOP BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              ElevatedButton(
                onPressed: marketRunning ? stopMarket : null,
                child: const Text("Stop Market"),
              ),

              const SizedBox(width: 20),

              ElevatedButton(
                onPressed: !marketRunning ? startMarket : null,
                child: const Text("Start Market"),
              ),

            ],
          ),

          const SizedBox(height: 20),

          /// LEADERBOARD TITLE
          const Text(
            "Live Leaderboard",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          /// LEADERBOARD
          Expanded(
            child: leaderboard.isEmpty
                ? const Center(
                    child: Text(
          "No users yet",
          style: TextStyle(color: Colors.grey),
        ),
                  )
                : ListView.builder(

                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: leaderboard.length,

                    itemBuilder: (context, index) {

                      final user = leaderboard[index];

                      return Container(

                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(12),
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

                                const SizedBox(width: 12),

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
          ),

        ],
      ),
    );
  }

  Future<void> logout() async {

  final confirm = await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text("Logout"),
          ),

        ],
      );
    },
  );

  if (confirm != true) return;

  SocketService.disconnect();

  final prefs = await SharedPreferences.getInstance();
  await prefs.remove("token");

  if (!mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const LoginScreen(),
    ),
    (route) => false,
  );
}
}
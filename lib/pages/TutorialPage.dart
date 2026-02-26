import 'package:flutter/material.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Tutorial"),
        backgroundColor: Colors.black,
      ),

      body: const Center(
        child: Text("Tutorial Page", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

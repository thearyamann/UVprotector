import 'package:flutter/material.dart';

void main() {
  runApp(const UVIndexApp());
}

class UVIndexApp extends StatelessWidget {
  const UVIndexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UV Index App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text("UV Index App"),
        ),
        body: const Center(
          child: Text("UV Tracker Starting..."),
        ),
      ),
    );
  }
}
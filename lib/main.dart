import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const UVProtectorApp());
}

class UVProtectorApp extends StatelessWidget {
  const UVProtectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UV Protector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
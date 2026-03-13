import 'package:flutter/material.dart';
import 'services/uv_controller.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {

  String result = "Loading...";

  @override
  void initState() {
    super.initState();
    testUV();
  }

  Future<void> testUV() async {

    final controller = UVController();

    try {

      final uvData = await controller.getCurrentUVData();

      setState(() {
        result =
            "UV Index: ${uvData.uvIndex}\n"
            "Risk Level: ${uvData.riskLevel}";
      });

    } catch (e) {

      setState(() {
        result = "Error: $e";
      });

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("UV Test"),
      ),
      body: Center(
        child: Text(
          result,
          textAlign: TextAlign.center,
        ),
      ),
    );

  }
}
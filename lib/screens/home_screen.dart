import 'package:flutter/material.dart';
import '../services/uv_controller.dart';
import '../models/uv_data.dart';
import '../models/skin_type.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UVController _controller = UVController();

  UVData? _uvData;
  bool _isLoading = false;
  String? _errorMessage;
  SkinType _selectedSkinType = SkinType.type3;

  Future<void> _loadUVData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _controller.getCurrentUVData(
        skinTypeNumber:
            _selectedSkinType.type, // dynamic — changes with user selection
      );
      setState(() => _uvData = data);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UV Protector')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Skin type dropdown — fully dynamic from SkinType.all
            const Text(
              'Your Skin Type:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<SkinType>(
              value: _selectedSkinType,
              isExpanded: true,
              items: SkinType.all
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text('Type ${s.type} — ${s.description}'),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSkinType = val);
              },
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _loadUVData,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Get UV Index'),
            ),

            const SizedBox(height: 30),

            if (_errorMessage != null)
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.red),
              ),

            // All values come directly from UVData — UI reads, never calculates
            if (_uvData != null) ...[
              Text(
                'UV Index: ${_uvData!.uvIndex}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Risk: ${_uvData!.riskLevel}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Burn time: ${_uvData!.burnTimeMinutes.toStringAsFixed(1)} mins',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(_uvData!.exposureAdvice, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                _uvData!.spfRecommendation,
                textAlign: TextAlign.center,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              Text(
                'Reapply sunscreen every ${_uvData!.reapplyMinutes} mins',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.blueGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

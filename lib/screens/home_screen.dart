import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/uv_controller.dart';
import '../models/uv_data.dart';
import '../models/skin_type.dart';
import '../theme/app_theme.dart';
import '../widgets/sun_icon.dart';
import '../widgets/uv_index_card.dart';
import '../widgets/skin_type_card.dart';
import '../widgets/reapply_card.dart';
import '../widgets/burn_time_card.dart';
import '../widgets/protection_card.dart';
import '../widgets/advice_card.dart';
import '../widgets/refresh_button.dart';
import '../services/location_service.dart';

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
        skinTypeNumber: _selectedSkinType.type,
      );
      setState(() => _uvData = data);
    } on LocationException catch (e) {
      setState(() => _errorMessage = e.message);

      if (e.type == LocationErrorType.permissionPermanentlyDenied) {
        _showOpenSettingsDialog();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Location Permission',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Location access is permanently denied.\n\nGo to Settings → UV Protector → Location → Allow.',
          style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(
                color: Color(0xFF3B7DD8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cycleSkinType() {
    final idx = SkinType.all.indexOf(_selectedSkinType);
    final next = (idx + 1) % SkinType.all.length;
    setState(() => _selectedSkinType = SkinType.all[next]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildGreeting(),
              const SizedBox(height: 16),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: UVIndexCard(uvData: _uvData)),
                    const SizedBox(width: AppTheme.cardGap),
                    Expanded(
                      child: SkinTypeCard(
                        selectedSkinType: _selectedSkinType,
                        onTap: _cycleSkinType,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.cardGap),

              ReapplyCard(uvData: _uvData, onReapplied: () {}),
              const SizedBox(height: AppTheme.cardGap),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: BurnTimeCard(uvData: _uvData)),
                    const SizedBox(width: AppTheme.cardGap),
                    Expanded(child: ProtectionCard(uvData: _uvData)),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.cardGap),

              AdviceCard(uvData: _uvData),
              const SizedBox(height: AppTheme.cardGap),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),

              RefreshButton(isLoading: _isLoading, onTap: _loadUVData),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SunIcon(),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppTheme.bgCard,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 18,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return const Padding(
      padding: EdgeInsets.only(left: 8, bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'UV Protector\n',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1a2332),
                height: 1.3,
              ),
            ),
            TextSpan(
              text: 'Ready for today?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: Color(0xFF4a5568),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

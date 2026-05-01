// File: lib/features/advisor/advisor_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme.dart';
import 'advisor_logic.dart';

class AdvisorScreen extends StatefulWidget {
  final List<String> inventoryItems;
  const AdvisorScreen({super.key, required this.inventoryItems});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  String _aiResponse = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load cached version immediately so the user isn't looking at a blank screen
    _aiResponse = AdvisorEngine.getCachedOnly();
    _fetchAIAdvice();
  }

  Future<void> _fetchAIAdvice() async {
    // This updates the UI once the fresh fetch completes
    final response = await AdvisorEngine.getAISurvivalStrategy(
        widget.inventoryItems,
        "Household in disaster zone"
    );

    if (mounted) {
      setState(() {
        _aiResponse = response;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              "https://images.unsplash.com/photo-1504150559433-c516936e92ce?auto=format&fit=crop&w=1200",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.85))),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "AI SURVIVAL HUB",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: (_aiResponse.contains("No data synced") && _isLoading)
                        ? _buildLoadingState()
                        : _buildAIResponseCard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.accent),
          SizedBox(height: 20),
          Text("Syncing with Global Advisor...", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildAIResponseCard() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: AppStyles.glass(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: AppColors.accent, size: 18),
                            SizedBox(width: 8),
                            Text("ADVISOR INSIGHTS", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        if (_isLoading)
                          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
                      ],
                    ),
                    const Divider(height: 32, color: Colors.white12),
                    Text(
                      _aiResponse,
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!_isLoading)
            const Text("Strategizing complete. Access this locally even without network.",
                style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }
}
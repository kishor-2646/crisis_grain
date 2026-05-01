// File: lib/features/civilian/survival_intelligence_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:ui';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../data/models/food_report.dart';
import '../advisor/advisor_logic.dart';
import '../advisor/advisor_screen.dart';

class SurvivalIntelligenceScreen extends StatefulWidget {
  const SurvivalIntelligenceScreen({super.key});

  @override
  State<SurvivalIntelligenceScreen> createState() => _SurvivalIntelligenceScreenState();
}

class _SurvivalIntelligenceScreenState extends State<SurvivalIntelligenceScreen> {
  int adults = 2;
  int children = 1;
  int elderly = 0;
  bool _isRefreshing = false;

  Future<void> _refreshAI(List<FoodReport> reports) async {
    setState(() => _isRefreshing = true);
    final items = reports.map((r) => r.itemName).toList();
    final contextStr = "$adults Adults, $children Children, $elderly Elderly";
    await AdvisorEngine.fetchAndCacheStrategy(items, contextStr);
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              "https://images.unsplash.com/photo-1464226184884-fa280b87c399?auto=format&fit=crop&w=1200",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.85))),

          SafeArea(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<FoodReport>(AppConstants.boxFoodReports).listenable(),
              builder: (context, Box<FoodReport> box, _) {
                final reports = box.values.toList();
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverHeader(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildHouseholdGlassCard(),
                            const SizedBox(height: 24),
                            _buildDetailedAnalysisCard(reports),
                            const SizedBox(height: 24),
                            _buildCachedAdviceCard(reports), // New: Localized AI advice
                            const SizedBox(height: 24),
                            _buildSmartAdvisorButton(reports),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("INTELLIGENCE UNIT", style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                Text("Survival Analysis", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseholdGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppStyles.glass(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.family_restroom, color: AppColors.accent, size: 20),
                  SizedBox(width: 10),
                  Text("HOUSEHOLD COMPOSITION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 20),
              _counter("Adults", adults, (v) => setState(() => adults = v)),
              _counter("Children", children, (v) => setState(() => children = v)),
              _counter("Elderly", elderly, (v) => setState(() => elderly = v)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _counter(String label, int val, Function(int) onSet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(onPressed: val > 0 ? () => onSet(val - 1) : null, icon: const Icon(Icons.remove, color: Colors.white70, size: 18)),
                Text("$val", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => onSet(val + 1), icon: const Icon(Icons.add, color: Colors.white, size: 18)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysisCard(List<FoodReport> reports) {
    double totalKcal = reports.fold(0.0, (sum, r) => sum + (r.quantity * 2500));
    int dailyNeed = (adults * 2100) + (children * 1400) + (elderly * 1800);
    double foodDays = dailyNeed > 0 ? (totalKcal / dailyNeed) : 0;

    double waterLiters = reports
        .where((r) => r.itemName.toLowerCase().contains('water'))
        .fold(0.0, (sum, r) => sum + r.quantity);
    double waterDays = (adults + children + elderly) > 0 ? (waterLiters / ((adults + children + elderly) * 3)) : 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: AppStyles.glass().copyWith(
              color: (foodDays < 3 && foodDays > 0) ? AppColors.error.withOpacity(0.15) : AppColors.primary.withOpacity(0.15)
          ),
          child: Column(
            children: [
              const Text("ESTIMATED SURVIVAL DURATION", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text("${foodDays.toStringAsFixed(1)} DAYS", style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              _survivalMetric("Food Energy", foodDays / 14, "${totalKcal.toInt()} kcal total"),
              const SizedBox(height: 12),
              _survivalMetric("Hydration", waterDays / 14, "${waterLiters.toStringAsFixed(1)} Liters"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCachedAdviceCard(List<FoodReport> reports) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(AppConstants.boxAiCache).listenable(),
      builder: (context, box, _) {
        final strategy = box.get('last_strategy', defaultValue: "No strategy synced yet.");
        final lastSync = box.get('last_sync', defaultValue: "Never");

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: AppStyles.glass(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("LOCAL AI INSIGHTS", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                      if (_isRefreshing)
                        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                      else
                        IconButton(
                          onPressed: () => _refreshAI(reports),
                          icon: const Icon(Icons.refresh, color: Colors.white38, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(strategy, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                  const Divider(color: Colors.white10, height: 24),
                  Text("Last updated: $lastSync", style: const TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _survivalMetric(String label, double percent, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent.clamp(0, 1),
          backgroundColor: Colors.white10,
          color: percent < 0.25 ? AppColors.error : AppColors.success,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildSmartAdvisorButton(List<FoodReport> reports) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: AppColors.accent.withOpacity(0.85),
            child: ElevatedButton(
              onPressed: () {
                final items = reports.map((r) => r.itemName).toList();
                Navigator.push(context, MaterialPageRoute(builder: (context) => AdvisorScreen(inventoryItems: items)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white),
                  SizedBox(width: 12),
                  Text("REQUEST AI SURVIVAL STRATEGY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
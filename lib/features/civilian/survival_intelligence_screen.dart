// File: lib/features/civilian/survival_intelligence_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../../data/models/food_report.dart';

class SurvivalIntelligenceScreen extends StatefulWidget {
  const SurvivalIntelligenceScreen({super.key});

  @override
  State<SurvivalIntelligenceScreen> createState() => _SurvivalIntelligenceScreenState();
}

class _SurvivalIntelligenceScreenState extends State<SurvivalIntelligenceScreen> {
  int adults = 2;
  int children = 1;
  int elderly = 0;

  // Caloric Constants (Humanitarian Standards)
  final int kcalAdult = 2100;
  final int kcalChild = 1400;
  final int kcalElderly = 1800;

  // Rough kcal per kg for common disaster foods
  final Map<String, int> kcalDensity = {
    'rice': 3600,
    'flour': 3600,
    'lentils': 3500,
    'oil': 8000,
    'canned': 1200,
    'bread': 2500,
    'biscuit': 4500,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Survival Intelligence")),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<FoodReport>(AppConstants.boxFoodReports).listenable(),
        builder: (context, Box<FoodReport> box, _) {
          final reports = box.values.toList();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHouseholdCard(),
                const SizedBox(height: 24),
                _buildSurvivalAnalysis(reports),
                const SizedBox(height: 24),
                _buildStorageAdvisor(reports),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHouseholdCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Household Composition", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _buildCounter("Adults", adults, (val) => setState(() => adults = val)),
            _buildCounter("Children", children, (val) => setState(() => children = val)),
            _buildCounter("Elderly", elderly, (val) => setState(() => elderly = val)),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              IconButton(onPressed: value > 0 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
              Text("$value", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add_circle_outline)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSurvivalAnalysis(List<FoodReport> reports) {
    double totalKcal = 0;
    for (var r in reports) {
      final name = r.itemName.toLowerCase();
      final density = kcalDensity.entries.firstWhere((e) => name.contains(e.key), orElse: () => const MapEntry('', 1000)).value;
      totalKcal += (r.quantity * density);
    }

    int dailyNeed = (adults * kcalAdult) + (children * kcalChild) + (elderly * kcalElderly);
    double daysLeft = dailyNeed > 0 ? (totalKcal / dailyNeed) : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: daysLeft < 3 && daysLeft > 0 ? AppColors.error : AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text("ESTIMATED SURVIVAL", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "${daysLeft.toStringAsFixed(1)} DAYS",
            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            "Stock: ${totalKcal.toInt()} kcal | Daily: $dailyNeed kcal",
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          if (daysLeft < 3 && daysLeft > 0)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text("⚠️ CRITICAL: Stock low. Seek NGO camp.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildStorageAdvisor(List<FoodReport> reports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Disaster Storage Priority", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...reports.map((r) {
          bool isPerishable = r.itemName.toLowerCase().contains('bread') || r.itemName.toLowerCase().contains('milk');
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                  isPerishable ? Icons.timer_outlined : Icons.shield_outlined, // FIXED: Corrected case
                  color: isPerishable ? Colors.orange : Colors.green
              ),
              title: Text(r.itemName),
              subtitle: Text(isPerishable ? "Eat within 48h (High Risk)" : "Safe for long term storage"),
              trailing: Text(
                  isPerishable ? "🔴 EAT FIRST" : "🟢 SAVE",
                  style: TextStyle(fontWeight: FontWeight.bold, color: isPerishable ? Colors.orange : Colors.green, fontSize: 10)
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
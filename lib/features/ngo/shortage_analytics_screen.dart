// File: lib/features/ngo/shortage_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Explicitly added for ValueListenable
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/food_need.dart';
import '../../data/models/camp.dart';

class ShortageAnalyticsScreen extends StatelessWidget {
  const ShortageAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Shortage Awareness")),
      body: MultiValueListenableBuilder(
        listenables: [
          Hive.box<FoodNeed>(AppConstants.boxFoodNeeds).listenable(),
          Hive.box<FoodCamp>(AppConstants.boxFoodCamps).listenable(),
        ],
        builder: (context, values, _) {
          final needsBox = Hive.box<FoodNeed>(AppConstants.boxFoodNeeds);
          final campsBox = Hive.box<FoodCamp>(AppConstants.boxFoodCamps);

          final needs = needsBox.values.toList();
          final camps = campsBox.values.toList();

          // Calculate Metrics
          final totalPeopleInNeed = needs.fold(0, (sum, item) => sum + item.peopleCount);
          final totalMealsAvailable = camps.fold(0, (sum, item) => sum + item.mealsAvailable);

          // Simple Area-based grouping
          Map<String, int> demandByArea = {};
          for (var need in needs) {
            demandByArea[need.locationArea] = (demandByArea[need.locationArea] ?? 0) + need.peopleCount;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(totalPeopleInNeed, totalMealsAvailable),
                const SizedBox(height: 24),
                _buildSectionHeader("High Demand Areas"),
                const SizedBox(height: 12),
                if (demandByArea.isEmpty)
                  const Center(child: Text("No data reported yet", style: TextStyle(color: Colors.grey)))
                else
                  ...demandByArea.entries.map((e) => _buildAreaDemandTile(e.key, e.value, totalPeopleInNeed)),
                const SizedBox(height: 24),
                _buildAlertCard(totalPeopleInNeed, totalMealsAvailable),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(int demand, int supply) {
    return Row(
      children: [
        Expanded(child: _buildStatTile("Total Demand", "$demand", Icons.group_outlined, AppColors.error)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatTile("Total Supply", "$supply", Icons.fastfood_outlined, AppColors.success)),
      ],
    );
  }

  Widget _buildStatTile(String label, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary));
  }

  Widget _buildAreaDemandTile(String area, int count, int total) {
    double ratio = total > 0 ? count / total : 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(area, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("$count people requesting food"),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              color: AppColors.error,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(int demand, int supply) {
    bool isShortage = demand > supply;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isShortage ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isShortage ? AppColors.error : AppColors.success),
      ),
      child: Row(
        children: [
          Icon(isShortage ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: isShortage ? AppColors.error : AppColors.success),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isShortage
                  ? "Warning: Demand exceeds supply by ${demand - supply} meals. Immediate action required."
                  : "Current supply is sufficient for all reported needs.",
              style: TextStyle(
                  color: isShortage ? AppColors.error : AppColors.success,
                  fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Updated helper class with explicit generic types
class MultiValueListenableBuilder extends StatelessWidget {
  final List<ValueListenable<dynamic>> listenables;
  final Widget Function(BuildContext context, List<dynamic> values, Widget? child) builder;

  const MultiValueListenableBuilder({
    super.key,
    required this.listenables,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, child) => builder(
          context,
          listenables.map((l) => l.value).toList(),
          child
      ),
    );
  }
}
// File: lib/features/civilian/civilian_home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../../data/models/food_need.dart';
import '../inventory/inventory_screen.dart';
import '../map/crisis_map_screen.dart';
import 'food_need_form.dart';
import 'survival_intelligence_screen.dart'; // Import Phase 5

class CivilianHomeScreen extends StatelessWidget {
  const CivilianHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(context),
          const SizedBox(height: 24),
          _buildSectionHeader("My Active Requests"),
          const SizedBox(height: 12),
          _buildNeedsList(),
          const SizedBox(height: 24),
          _buildSectionHeader("Survival Toolkit"),
          const SizedBox(height: 12),
          _buildToolGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Facing Food Shortage?",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Report your needs so NGOs and volunteers can coordinate better.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FoodNeedForm()),
            ),
            icon: const Icon(Icons.add_alert),
            label: const Text("Request Food Now"),
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }

  Widget _buildNeedsList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<FoodNeed>(AppConstants.boxFoodNeeds).listenable(),
      builder: (context, Box<FoodNeed> box, _) {
        if (box.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("No requests sent yet.", style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        final needs = box.values.toList().reversed.toList();
        return Column(
          children: needs.take(2).map((need) => _buildNeedCard(need)).toList(),
        );
      },
    );
  }

  Widget _buildNeedCard(FoodNeed need) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.warning,
          child: Icon(Icons.people, color: Colors.white),
        ),
        title: Text("Need for ${need.peopleCount} People"),
        subtitle: Text("Area: ${need.locationArea}"),
        trailing: Icon(
          need.isSentViaSMS ? Icons.sms_outlined : Icons.cloud_off,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildToolGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildToolCard(
          context,
          "Survival IQ",
          "Kcal & Storage Advice",
          Icons.psychology_outlined,
          AppColors.warning,
          const SurvivalIntelligenceScreen(),
        ),
        _buildToolCard(
          context,
          "Food Map",
          "Find nearby camps",
          Icons.map_outlined,
          AppColors.accent,
          const CrisisMapScreen(),
        ),
        _buildToolCard(
          context,
          "My Stocks",
          "Log your inventory",
          Icons.inventory_2_outlined,
          AppColors.success,
          const InventoryScreen(),
        ),
      ],
    );
  }

  Widget _buildToolCard(BuildContext context, String title, String sub, IconData icon, Color color, Widget destination) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(sub, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
// File: lib/features/ngo/ngo_home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../../data/models/camp.dart';
import 'create_camp_form.dart';
import 'shortage_analytics_screen.dart'; // Import Phase 6

class NGOHomeScreen extends StatelessWidget {
  const NGOHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Active Food Camps"),
        actions: [
          IconButton(
            tooltip: "Shortage Awareness",
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShortageAnalyticsScreen()),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<FoodCamp>(AppConstants.boxFoodCamps).listenable(),
        builder: (context, Box<FoodCamp> box, _) {
          if (box.isEmpty) {
            return _buildEmptyState(context);
          }

          final camps = box.values.toList().reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: camps.length,
            itemBuilder: (context, index) {
              final camp = camps[index];
              return _buildCampCard(context, camp);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateCampForm()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text("New Food Camp", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.villa_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No active food camps created", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateCampForm()),
            ),
            child: const Text("Set Up First Camp"),
          ),
        ],
      ),
    );
  }

  Widget _buildCampCard(BuildContext context, FoodCamp camp) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    camp.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(camp.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(camp.time, style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(camp.location, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Meals Available", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      "${camp.mealsAvailable}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Verify Code", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      camp.verificationCode,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                          letterSpacing: 2
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.green;
    if (status == "LOW") color = Colors.orange;
    if (status == "CLOSED") color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
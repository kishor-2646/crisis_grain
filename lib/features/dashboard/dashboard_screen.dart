// File: lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../../data/models/food_report.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure box is open before trying to access it
    if (!Hive.isBoxOpen('foodReports')) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("NGO Overview Dashboard"),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<FoodReport>('foodReports').listenable(),
        builder: (context, Box<FoodReport> box, _) {
          final reports = box.values.toList();

          // Analytical Data Calculations
          final criticalCount = reports.where((r) => r.urgency == AppUrgency.critical).length;
          final lowCount = reports.where((r) => r.urgency == AppUrgency.low).length;
          final totalKg = reports.fold(0.0, (sum, r) => sum + r.quantity);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Zone Status Summary"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Critical Needs", criticalCount.toString(), AppColors.error)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("Running Low", lowCount.toString(), AppColors.warning)),
                  ],
                ),
                const SizedBox(height: 12),
                // Removed Expanded here to prevent layout crash in SingleChildScrollView
                _buildStatCard("Total Food Volume", "${totalKg.toStringAsFixed(1)} kg", AppColors.primary),

                const SizedBox(height: 24),
                _buildSectionHeader("Top Requested Items"),
                const SizedBox(height: 12),
                _buildItemBar("Rice", reports.isEmpty ? 0 : (reports.where((r) => r.itemName.toLowerCase().contains('rice')).length / reports.length)),
                _buildItemBar("Bread", reports.isEmpty ? 0 : (reports.where((r) => r.itemName.toLowerCase().contains('bread')).length / reports.length)),
                _buildItemBar("Water", reports.isEmpty ? 0 : (reports.where((r) => r.itemName.toLowerCase().contains('water')).length / reports.length)),

                const SizedBox(height: 24),
                _buildActionCard(
                  context,
                  "Cloud Sync Status",
                  reports.any((r) => !r.isSynced) ? "Pending sync..." : "All data backed up",
                  reports.any((r) => !r.isSynced) ? Icons.cloud_upload : Icons.cloud_done,
                  reports.any((r) => !r.isSynced) ? AppColors.warning : AppColors.success,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }

  // FIXED: Removed the internal 'Expanded' widget to make it safe for use anywhere
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildItemBar(String name, double percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            color: AppColors.primary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String sub, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.sync_outlined),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cloud sync is automatic when internet is detected.")),
          );
        },
      ),
    );
  }
}
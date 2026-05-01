// File: lib/features/inventory/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/food_report.dart';
import '../map/crisis_map_screen.dart';
import '../advisor/advisor_screen.dart';
import '../sync/qr_sync_screen.dart';
import '../dashboard/dashboard_screen.dart'; // Import Phase 5

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CrisisGrain Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Navigation to NGO Dashboard (Phase 5)
          IconButton(
            tooltip: "Analytics Dashboard",
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            ),
          ),
          // Navigation to Sync Engine (Phase 4)
          IconButton(
            tooltip: "Sync & Share",
            icon: const Icon(Icons.sync),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QRSyncScreen()),
            ),
          ),
          // Navigation to AI Advisor (Phase 3)
          IconButton(
            tooltip: "AI Advisor",
            icon: const Icon(Icons.psychology_outlined),
            onPressed: () {
              final box = Hive.box<FoodReport>('foodReports');
              final items = box.values.map((e) => e.itemName).toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdvisorScreen(inventoryItems: items),
                ),
              );
            },
          ),
          // Navigation to Map (Phase 2)
          IconButton(
            tooltip: "View Map",
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CrisisMapScreen()),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<FoodReport>('foodReports').listenable(),
        builder: (context, Box<FoodReport> box, _) {
          if (box.values.isEmpty) {
            return _buildEmptyState();
          }

          final reports = box.values.toList().reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 80),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppUrgency.getColor(report.urgency).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.inventory_2, color: AppUrgency.getColor(report.urgency)),
                  ),
                  title: Text(report.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text("${report.quantity} ${report.unit} • Status: ${report.urgency}"),
                  ),
                  trailing: Icon(
                    report.isSynced ? Icons.cloud_done : Icons.cloud_off,
                    color: report.isSynced ? AppColors.success : Colors.grey,
                    size: 20,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReportDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Report", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_food_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No reports found locally", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  void _showAddReportDialog(BuildContext context) {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    String urgency = AppUrgency.surplus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Log Food Availability", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Item Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: "Quantity (e.g. 10)", border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: urgency,
              decoration: const InputDecoration(labelText: "Need Status", border: OutlineInputBorder()),
              items: [AppUrgency.surplus, AppUrgency.low, AppUrgency.critical]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => urgency = val!,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (nameController.text.isEmpty) return;

                final report = FoodReport(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  itemName: nameController.text,
                  quantity: double.tryParse(qtyController.text) ?? 0,
                  unit: "kg",
                  urgency: urgency,
                  lat: 33.3152 + (DateTime.now().millisecond / 100000),
                  lng: 44.3661 + (DateTime.now().microsecond / 1000000),
                  createdAt: DateTime.now(),
                );

                Hive.box<FoodReport>('foodReports').add(report);
                Navigator.pop(context);
              },
              child: const Text("Save Offline", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
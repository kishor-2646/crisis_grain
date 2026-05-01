// File: lib/features/map/crisis_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../../data/models/food_report.dart';

class CrisisMapScreen extends StatelessWidget {
  const CrisisMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Food Map"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<FoodReport>('foodReports').listenable(),
        builder: (context, Box<FoodReport> box, _) {
          final reports = box.values.toList();

          return FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(33.3152, 44.3661), // Baghdad Center
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.crisisgrain.app',
                // Note: For full offline, tiles would be pre-cached in the assets or local storage.
              ),
              MarkerLayer(
                markers: reports.map((report) {
                  return Marker(
                    point: LatLng(report.lat, report.lng),
                    width: 45,
                    height: 45,
                    child: GestureDetector(
                      onTap: () => _showReportDetails(context, report),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppUrgency.getColor(report.urgency),
                            size: 45,
                          ),
                          Positioned(
                            top: 8,
                            child: Icon(
                              Icons.circle,
                              color: Colors.white.withOpacity(0.8),
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("In a crisis zone? Tap 'New Report' in Inventory to pin your status.")),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  void _showReportDetails(BuildContext context, FoodReport report) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: AppUrgency.getColor(report.urgency)),
                const SizedBox(width: 12),
                Text(report.itemName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            _detailRow(Icons.scale, "Quantity", "${report.quantity} ${report.unit}"),
            const SizedBox(height: 12),
            _detailRow(Icons.priority_high, "Urgency", report.urgency),
            const SizedBox(height: 12),
            _detailRow(Icons.calendar_today, "Reported", report.createdAt.toString().split('.')[0]),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Back to Map", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value),
      ],
    );
  }
}
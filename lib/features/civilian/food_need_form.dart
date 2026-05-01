// File: lib/features/civilian/food_need_form.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants.dart';
import '../../data/models/food_need.dart';

class FoodNeedForm extends StatefulWidget {
  const FoodNeedForm({super.key});

  @override
  State<FoodNeedForm> createState() => _FoodNeedFormState();
}

class _FoodNeedFormState extends State<FoodNeedForm> {
  final _countController = TextEditingController();
  final _areaController = TextEditingController();

  void _submitNeed() async {
    if (_countController.text.isEmpty || _areaController.text.isEmpty) return;

    final need = FoodNeed(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      peopleCount: int.tryParse(_countController.text) ?? 1,
      locationArea: _areaController.text,
      createdAt: DateTime.now(),
      isSentViaSMS: true, // For demo, we assume SMS intent
    );

    await Hive.box<FoodNeed>(AppConstants.boxFoodNeeds).add(need);

    if (mounted) {
      _showSMSSimulation(need);
    }
  }

  void _showSMSSimulation(FoodNeed need) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("SMS Broadcast Preview"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("This message will be sent to the local gateway:"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: Text(
                "CG NEED ${need.peopleCount} PEOPLE | AREA: ${need.locationArea}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back home
            },
            child: const Text("SEND SMS"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Assistance")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("How many people need food?", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "e.g., 4", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text("Your Area / Neighborhood", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _areaController,
              decoration: const InputDecoration(hintText: "e.g., Sector 4 North", border: OutlineInputBorder()),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submitNeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text("Send Request via SMS", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
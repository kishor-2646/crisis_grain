// File: lib/features/ngo/create_camp_form.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants.dart';
import '../../data/models/camp.dart';

class CreateCampForm extends StatefulWidget {
  const CreateCampForm({super.key});

  @override
  State<CreateCampForm> createState() => _CreateCampFormState();
}

class _CreateCampFormState extends State<CreateCampForm> {
  final _nameController = TextEditingController();
  final _locController = TextEditingController();
  final _timeController = TextEditingController();
  final _qtyController = TextEditingController();

  String _generateVerificationCode() {
    // Generates the 4-digit code (WOW feature)
    return (Random().nextInt(9000) + 1000).toString();
  }

  void _saveCamp() async {
    if (_nameController.text.isEmpty || _locController.text.isEmpty) return;

    final code = _generateVerificationCode();
    final camp = FoodCamp(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      location: _locController.text,
      time: _timeController.text,
      mealsAvailable: int.tryParse(_qtyController.text) ?? 100,
      verificationCode: code,
      status: "OPEN",
    );

    await Hive.box<FoodCamp>(AppConstants.boxFoodCamps).add(camp);

    if (mounted) {
      _showSMSBroadcastPreview(camp);
    }
  }

  void _showSMSBroadcastPreview(FoodCamp camp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("SMS Broadcast Alert"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sending alert to all civilians in area:"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: Text(
                "FOOD CAMP | ${camp.name} | @${camp.location} | ${camp.time} | CODE: ${camp.verificationCode}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to NGO dashboard
            },
            child: const Text("BROADCAST NOW"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Up Food Camp")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Camp / Shelter Name", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: "e.g., Red Cross School Ground", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text("Exact Location", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _locController,
              decoration: const InputDecoration(hintText: "e.g., Near Main Gate, Sector 4", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Time", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _timeController,
                        decoration: const InputDecoration(hintText: "e.g., 5:00 PM", border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Meal Quantity", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: "e.g., 200", border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveCamp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text("Activate Camp & Broadcast", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
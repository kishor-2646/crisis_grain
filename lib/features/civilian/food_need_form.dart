// File: lib/features/civilian/food_need_form.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/constants.dart';
import '../../core/sms_utils.dart';
import '../../data/models/food_need.dart';

class FoodNeedForm extends StatefulWidget {
  const FoodNeedForm({super.key});

  @override
  State<FoodNeedForm> createState() => _FoodNeedFormState();
}

class _FoodNeedFormState extends State<FoodNeedForm> {
  final _countController = TextEditingController();
  final _areaController = TextEditingController();
  final _phoneController = TextEditingController();

  void _processSubmission() async {
    final count = int.tryParse(_countController.text) ?? 1;
    final area = _areaController.text.trim();
    final phone = _phoneController.text.trim();

    if (area.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    final need = FoodNeed(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      peopleCount: count,
      locationArea: area,
      phoneNumber: phone,
      createdAt: DateTime.now(),
    );

    // 1. Save to Local Hive
    await Hive.box<FoodNeed>(AppConstants.boxFoodNeeds).add(need);

    // 2. Check Connectivity for Fallback
    final results = await Connectivity().checkConnectivity();
    // Handling both singular and list result versions of connectivity_plus
    final hasNoSignal = results is List
        ? (results as List).every((r) => r == ConnectivityResult.none)
        : results == ConnectivityResult.none;

    if (hasNoSignal) {
      _showSMSDialog(count, area);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signal found. Syncing to NGO map...")),
      );
      Navigator.pop(context);
    }
  }

  void _showSMSDialog(int count, String area) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("📡 No Internet Connection"),
        content: const Text("Would you like to send this request via SMS to our emergency relief line?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("LATER"),
          ),
          ElevatedButton(
            onPressed: () {
              final msg = SMSUtils.generateNeedMessage(count, area);
              SMSUtils.launchSMS(msg);
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Back to Home
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
      appBar: AppBar(title: const Text("Request Food")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "How many people?",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: "Current Location / Area",
                hintText: "e.g. Sector 7",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Your Phone Number",
                hintText: "Required for rescue coordination",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _processSubmission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "SUBMIT REQUEST",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
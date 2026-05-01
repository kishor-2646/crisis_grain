// File: lib/features/ngo/create_camp_form.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants.dart';
import '../../core/sms_utils.dart';
import '../../data/models/camp.dart';
import '../../data/models/food_need.dart';

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
    return (1000 + (DateTime.now().millisecond % 9000)).toString();
  }

  void _saveCamp() async {
    final name = _nameController.text.trim();
    final location = _locController.text.trim();

    if (name.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in the camp name and location")),
      );
      return;
    }

    final code = _generateVerificationCode();
    final camp = FoodCamp(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      location: location,
      time: _timeController.text.isEmpty ? "Today" : _timeController.text,
      mealsAvailable: int.tryParse(_qtyController.text) ?? 100,
      verificationCode: code,
      status: "OPEN",
    );

    // Save locally
    await Hive.box<FoodCamp>(AppConstants.boxFoodCamps).add(camp);

    if (mounted) {
      _showBroadcastOption(camp);
    }
  }

  void _showBroadcastOption(FoodCamp camp) {
    // 1. FILTER RECIPIENTS: Find everyone in this specific area from our local needs box
    final box = Hive.box<FoodNeed>(AppConstants.boxFoodNeeds);

    // Normalize area strings for better matching
    final targetArea = camp.location.toLowerCase().trim();

    final List<String> areaPhoneNumbers = box.values
        .where((need) => need.locationArea.toLowerCase().trim() == targetArea)
        .map((need) => need.phoneNumber)
        .where((phone) => phone.isNotEmpty)
        .toSet() // Ensure unique numbers
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Camp Activated!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Camp: ${camp.name}"),
            const SizedBox(height: 8),
            Text("Found ${areaPhoneNumbers.length} recipients in ${camp.location}."),
            const SizedBox(height: 12),
            const Text(
              "Would you like to broadcast the verification code to them via SMS?",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("NO, SKIP"),
          ),
          ElevatedButton(
            onPressed: () {
              final msg = SMSUtils.generateCampBroadcast(
                  camp.name,
                  camp.location,
                  camp.verificationCode
              );

              // 2. BROADCAST: Send to the collected list of numbers
              SMSUtils.launchSMS(msg, recipients: areaPhoneNumbers);

              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("BROADCAST SMS"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Set Up New Camp")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Camp Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locController,
              decoration: const InputDecoration(
                labelText: "Location Area (Matches Demand Area)",
                hintText: "e.g. Sector 7",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: "Activation Time",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Initial Meal Stock",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveCamp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "ACTIVATE CAMP",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
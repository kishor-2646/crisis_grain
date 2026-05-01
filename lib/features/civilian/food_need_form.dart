// File: lib/features/civilian/food_need_form.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    final countText = _countController.text.trim();
    final area = _areaController.text.trim();
    final phone = _phoneController.text.trim();

    if (area.isEmpty || phone.isEmpty || countText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    final count = int.tryParse(countText) ?? 1;

    // 1. Create and Save the model instance
    final need = FoodNeed(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      peopleCount: count,
      locationArea: area,
      phoneNumber: phone, // This must match the model's required field
      createdAt: DateTime.now(),
      isSentViaSMS: false,
      isSynced: false,
    );

    // Save to Hive
    final box = Hive.box<FoodNeed>(AppConstants.boxFoodNeeds);
    await box.add(need);

    if (mounted) {
      _showSmsPushDialog(count, area);
    }
  }

  void _showSmsPushDialog(int count, String area) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 60),
            SizedBox(height: 10),
            Text("Request Logged", textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Your request for $count people in $area has been saved locally.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "DEMO SMS PUSH:",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              "Push this request to the nearby Sector 7 Camp coordinator via SMS.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              final msg = SMSUtils.generateNeedMessage(count, area);
              // Hardcoded demo number for hackathon presentation
              SMSUtils.launchSMS(msg, recipients: ["+919876543210"]);

              Navigator.pop(context);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.send_rounded),
            label: const Text("PUSH SMS TO CAMP"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("CLOSE", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Request Emergency Food")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildInputField(_countController, "How many people?", Icons.people, TextInputType.number),
            const SizedBox(height: 16),
            _buildInputField(_areaController, "Location / Area", Icons.location_on, TextInputType.text),
            const SizedBox(height: 16),
            _buildInputField(_phoneController, "Your Phone Number", Icons.phone, TextInputType.phone),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _processSubmission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("SUBMIT REQUEST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController ctrl, String label, IconData icon, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
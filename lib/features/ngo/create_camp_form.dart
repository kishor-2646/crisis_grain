// File: lib/features/ngo/create_camp_form.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants.dart';
import '../../core/sms_utils.dart';
import '../../core/sync_service.dart'; // Import SyncService for cloud fetch
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
  bool _isBroadcasting = false;

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

  void _showBroadcastOption(FoodCamp camp) async {
    setState(() => _isBroadcasting = true);

    // 1. FETCH RECIPIENTS: Hybrid Search
    // First, try Cloud (to find all civilians in area)
    List<String> recipients = await SyncService().getCloudPhoneNumbersForArea(camp.location);

    // Second, Merge with Local (in case any were created offline on this device)
    final localBox = Hive.box<FoodNeed>(AppConstants.boxFoodNeeds);
    final targetArea = camp.location.toLowerCase().trim();
    final localNumbers = localBox.values
        .where((n) => n.locationArea.toLowerCase().trim() == targetArea)
        .map((n) => n.phoneNumber)
        .toList();

    // Combine and deduplicate
    final finalRecipients = {...recipients, ...localNumbers}.toList();

    setState(() => _isBroadcasting = false);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Broadcast Alert"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ready to notify ${finalRecipients.length} civilians in ${camp.location}."),
            const SizedBox(height: 12),
            const Text(
              "This will open your SMS app with all numbers pre-filled as a bulk message.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("SKIP"),
          ),
          ElevatedButton(
            onPressed: () {
              final msg = SMSUtils.generateCampBroadcast(
                  camp.name,
                  camp.location,
                  camp.verificationCode
              );

              // 2. BULK SMS: Send to everyone found in the cloud + local
              SMSUtils.launchSMS(msg, recipients: finalRecipients);

              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("SEND BULK SMS"),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Camp Name", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locController,
                  decoration: const InputDecoration(
                      labelText: "Location Area",
                      hintText: "e.g. Sector 7",
                      border: OutlineInputBorder()
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(labelText: "Time", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Initial Meals", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isBroadcasting ? null : _saveCamp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  child: Text(
                    _isBroadcasting ? "FETCHING RECIPIENTS..." : "ACTIVATE & BROADCAST",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          if (_isBroadcasting)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
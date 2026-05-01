// File: lib/features/ngo/create_camp_form.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants.dart';
import '../../core/sms_utils.dart';
import '../../core/sync_service.dart';
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
    List<String> recipients = await SyncService().getCloudPhoneNumbersForArea(camp.location);

    final localBox = Hive.box<FoodNeed>(AppConstants.boxFoodNeeds);
    final targetArea = camp.location.toLowerCase().trim();
    final localNumbers = localBox.values
        .where((n) => n.locationArea.toLowerCase().trim() == targetArea)
        .map((n) => n.phoneNumber)
        .toList();

    final finalRecipients = {...recipients, ...localNumbers}.toList();

    setState(() => _isBroadcasting = false);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Camp Activated!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ready to notify ${finalRecipients.length} civilians in ${camp.location}."),
            const SizedBox(height: 12),
            const Text(
              "Choose Broadcast Method:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        actions: [
          // Option 1: Native SMS (Bulk)
          ElevatedButton.icon(
            onPressed: () {
              final msg = SMSUtils.generateCampBroadcast(camp.name, camp.location, camp.verificationCode);
              SMSUtils.launchSMS(msg, recipients: finalRecipients);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.message, size: 18),
            label: const Text("SEND BULK SMS"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
          ),
          const SizedBox(height: 8),
          // Option 2: Professional Gateway Broadcast (Simulation)
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              _triggerGateway(camp);
            },
            icon: const Icon(Icons.router, size: 18),
            label: const Text("GOVT. GATEWAY BROADCAST"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL / SKIP"),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowButtonSpacing: 8,
      ),
    );
  }

  void _triggerGateway(FoodCamp camp) async {
    // Show a global loader for the simulation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
    );

    final msg = SMSUtils.generateCampBroadcast(camp.name, camp.location, camp.verificationCode);
    final success = await SMSUtils.triggerGatewayBroadcast(
      areaName: camp.location,
      message: msg,
    );

    if (!mounted) return;
    Navigator.pop(context); // Remove loader

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Success: Request sent to Central Emergency Gateway for ${camp.location}"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context); // Go back home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gateway Error: Unable to reach broadcast server"), backgroundColor: Colors.red),
      );
    }
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
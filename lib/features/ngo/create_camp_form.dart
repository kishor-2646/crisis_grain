// File: lib/features/ngo/create_camp_form.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:ui';
import '../../core/constants.dart';
import '../../core/theme.dart';
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

    // Constructing model with required 'contactPhone'
    final camp = FoodCamp(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      location: location,
      time: _timeController.text.isEmpty ? "Today" : _timeController.text,
      mealsAvailable: int.tryParse(_qtyController.text) ?? 100,
      verificationCode: code,
      status: "OPEN",
      contactPhone: "+910000000000", // Demo coordinator number
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
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.white24, width: 1.5),
          ),
          title: const Text("Camp Activated!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ready to notify ${finalRecipients.length} civilians in ${camp.location}.",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              const Text(
                "Choose Broadcast Method:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                final msg = SMSUtils.generateCampBroadcast(camp.name, camp.location, camp.verificationCode);
                SMSUtils.launchSMS(msg, recipients: finalRecipients);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.message, size: 18),
              label: const Text("SEND BULK SMS"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context); // Close dialog first
                _triggerGateway(camp, finalRecipients); // Passing computed recipients
              },
              icon: const Icon(Icons.router, size: 18),
              label: const Text("GOVT. GATEWAY BROADCAST"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL / SKIP", style: TextStyle(color: Colors.white60)),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
          actionsOverflowButtonSpacing: 8,
        ),
      ),
    );
  }

  void _triggerGateway(FoodCamp camp, List<String> recipients) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final msg = SMSUtils.generateCampBroadcast(camp.name, camp.location, camp.verificationCode);
    final success = await SMSUtils.triggerGatewayBroadcast(
      areaName: camp.location,
      message: msg,
      recipients: recipients, // Fixed: recipients parameter is now passed correctly
    );

    if (!mounted) return;
    Navigator.pop(context); // Remove loader

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Success: Request sent to Central Emergency Gateway for ${camp.location}"),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context); // Go back home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gateway Error: Unable to reach broadcast server"), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Set Up New Camp"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Image (Humanitarian Logistics)
          Positioned.fill(
            child: Image.network(
              "https://images.unsplash.com/photo-1594708767771-a7502209ff51?auto=format&fit=crop&w=1200",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.8))),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Establishing a new food distribution point",
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _buildGlassField(_nameController, "Camp Name", Icons.business, hint: "e.g. Hope Center"),
                  const SizedBox(height: 16),
                  _buildGlassField(_locController, "Location Area", Icons.location_on, hint: "e.g. Sector 7"),
                  const SizedBox(height: 16),
                  _buildGlassField(_timeController, "Operating Hours", Icons.access_time, hint: "e.g. 09:00 AM - 06:00 PM"),
                  const SizedBox(height: 16),
                  _buildGlassField(_qtyController, "Initial Meal Stock", Icons.restaurant, type: TextInputType.number, hint: "100"),
                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
          if (_isBroadcasting)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassField(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text, String? hint}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: TextField(
          controller: ctrl,
          keyboardType: type,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: Icon(icon, color: AppColors.accent),
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white24)),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ElevatedButton(
              onPressed: _isBroadcasting ? null : _saveCamp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                _isBroadcasting ? "FETCHING RECIPIENTS..." : "ACTIVATE & BROADCAST",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
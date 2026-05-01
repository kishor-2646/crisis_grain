// File: lib/features/volunteer/volunteer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../../data/models/camp.dart';

class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({super.key});

  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen> {
  final _codeController = TextEditingController();
  FoodCamp? _selectedCamp;

  void _verifyAndDistribute() async {
    if (_selectedCamp == null || _codeController.text.isEmpty) return;

    if (_codeController.text == _selectedCamp!.verificationCode) {
      if (_selectedCamp!.mealsAvailable > 0) {
        setState(() {
          _selectedCamp!.mealsAvailable -= 1;
        });
        await _selectedCamp!.save(); // Persist to Hive

        _showSuccessDialog();
        _codeController.clear();
      } else {
        _showErrorDialog("No meals left in this camp.");
      }
    } else {
      _showErrorDialog("Invalid Verification Code.");
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 50),
        title: const Text("Verified Successfully"),
        content: const Text("1 Meal has been deducted from the camp stock. You can now hand over the food."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: AppColors.error, size: 50),
        title: const Text("Verification Failed"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Try Again")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<FoodCamp>(AppConstants.boxFoodCamps).listenable(),
      builder: (context, Box<FoodCamp> box, _) {
        if (box.isEmpty) {
          return const Center(child: Text("No active camps found. NGO must create a camp first."));
        }

        final camps = box.values.toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Your Assigned Camp", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<FoodCamp>(
                value: _selectedCamp,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: camps.map((camp) {
                  return DropdownMenuItem(
                    value: camp,
                    child: Text("${camp.name} (${camp.mealsAvailable} left)"),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCamp = val),
              ),
              const SizedBox(height: 32),
              if (_selectedCamp != null) ...[
                const Center(
                  child: Text(
                    "Enter 4-Digit Code from Civilian",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 10),
                  decoration: const InputDecoration(
                    counterText: "",
                    hintText: "0000",
                    border: UnderlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _verifyAndDistribute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "VERIFY & RELEASE MEAL",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "Remaining Meals: ${_selectedCamp!.mealsAvailable}",
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
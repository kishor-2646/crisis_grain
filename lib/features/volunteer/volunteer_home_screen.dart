// File: lib/features/volunteer/volunteer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:ui';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/camp.dart';

class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({super.key});

  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen> {
  final _codeController = TextEditingController();
  FoodCamp? _selectedCamp;

  void _verify() async {
    if (_selectedCamp == null || _codeController.text.isEmpty) return;
    if (_codeController.text == _selectedCamp!.verificationCode) {
      if (_selectedCamp!.mealsAvailable > 0) {
        setState(() => _selectedCamp!.mealsAvailable -= 1);
        await _selectedCamp!.save();
        _showDialog(Icons.check_circle, "Verified", "Meal released successfully.", AppColors.success);
        _codeController.clear();
      } else {
        _showDialog(Icons.warning, "Stock Out", "No meals left in this camp.", AppColors.warning);
      }
    } else {
      _showDialog(Icons.error, "Invalid Code", "Verification failed. Check the code.", AppColors.error);
    }
  }

  void _showDialog(IconData icon, String title, String msg, Color color) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: color.withOpacity(0.3), width: 1.5)
          ),
          icon: Icon(icon, color: color, size: 40),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(msg, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image with Darker Scrim for Contrast
          Positioned.fill(
            child: Image.network(
              "https://images.unsplash.com/photo-1593113598332-cd288d649433?auto=format&fit=crop&w=1200",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.85))),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                        "DISTRIBUTION HUB",
                        style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontSize: 10
                        )
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      "Meal Verification",
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 40),

                  _buildCampSelector(),
                  const SizedBox(height: 30),

                  if (_selectedCamp != null) ...[
                    _buildVerificationInput(),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampSelector() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<FoodCamp>(AppConstants.boxFoodCamps).listenable(),
      builder: (context, Box<FoodCamp> box, _) {
        final camps = box.values.toList();
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: AppStyles.glass(radius: 20).copyWith(
                  color: Colors.white.withOpacity(0.08)
              ),
              child: DropdownButtonFormField<FoodCamp>(
                value: _selectedCamp,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: "Assign Distribution Camp",
                    labelStyle: TextStyle(color: Colors.white70, fontSize: 14)
                ),
                items: camps.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.name, style: const TextStyle(color: Colors.white))
                )).toList(),
                onChanged: (val) => setState(() => _selectedCamp = val),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerificationInput() {
    return Column(
      children: [
        const Text(
            "ENTER 4-DIGIT CIVILIAN CODE",
            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: AppStyles.glass().copyWith(
                  color: Colors.white.withOpacity(0.05)
              ),
              child: TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 24
                ),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: "",
                    hintText: "0000",
                    hintStyle: TextStyle(color: Colors.white10)
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.2),
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
              color: AppColors.accent.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ElevatedButton(
              onPressed: _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                  "VERIFY & RELEASE MEAL",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)
              ),
            ),
          ),
        ),
      ),
    );
  }
}
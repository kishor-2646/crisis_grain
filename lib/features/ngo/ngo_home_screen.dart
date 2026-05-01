// File: lib/features/ngo/ngo_home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:ui';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/camp.dart';
import 'create_camp_form.dart';
import 'shortage_analytics_screen.dart';

class NGOHomeScreen extends StatelessWidget {
  const NGOHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Immersive NGO Background (Management/Logistics focus)
          Positioned.fill(
            child: Image.network(
              "https://images.unsplash.com/photo-1469571483311-0b9e81d72567?auto=format&fit=crop&w=1200",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.75))),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverHeader(context),
                _buildCampList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildGlassFAB(context),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CENTRAL COMMAND",
                  style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 10),
                ),
                const Text(
                  "NGO Panel",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            _buildHeaderAction(context, Icons.analytics_outlined, const ShortageAnalyticsScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAction(BuildContext context, IconData icon, Widget target) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: AppStyles.glass(radius: 12),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => target)),
          ),
        ),
      ),
    );
  }

  Widget _buildCampList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<FoodCamp>(AppConstants.boxFoodCamps).listenable(),
      builder: (context, Box<FoodCamp> box, _) {
        if (box.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text("No active camps found", style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
          );
        }

        final camps = box.values.toList().reversed.toList();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final camp = camps[index];
                return _buildGlassCampCard(camp);
              },
              childCount: camps.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassCampCard(FoodCamp camp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.glass(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(camp.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    _buildStatusChip(camp.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text(camp.location, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text(camp.time, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Colors.white10),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("MEALS LEFT", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("${camp.mealsAvailable}", style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("AUTH CODE", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(camp.verificationCode, style: const TextStyle(color: AppColors.accent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = AppColors.success;
    if (status == "LOW") color = AppColors.warning;
    if (status == "CLOSED") color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGlassFAB(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateCampForm())),
          backgroundColor: AppColors.primary.withOpacity(0.8),
          icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
          label: const Text("ESTABLISH CAMP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
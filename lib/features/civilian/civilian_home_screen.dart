// File: lib/features/civilian/civilian_home_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/food_need.dart';
import '../../data/models/food_report.dart';
import '../../data/models/camp.dart';
import 'food_need_form.dart';
import 'survival_intelligence_screen.dart';
import '../map/crisis_map_screen.dart';
import '../inventory/inventory_screen.dart';

class CivilianHomeScreen extends StatefulWidget {
  const CivilianHomeScreen({super.key});

  @override
  State<CivilianHomeScreen> createState() => _CivilianHomeScreenState();
}

class _CivilianHomeScreenState extends State<CivilianHomeScreen> {
  // Default to Bengaluru coordinates
  LatLng _currentPos = const LatLng(12.9716, 77.5946);
  bool _isLoadingMap = true;
  String? _cachePath;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initializeOfflineMap();
  }

  Future<void> _initializeOfflineMap() async {
    // 1. Prepare Cache Directory
    final cacheDir = await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() {
        _cachePath = '${cacheDir.path}/map_cache_v1';
      });
    }

    // 2. Resilient Location Fetching (No more infinite loading)
    await _determineResilientPosition();
  }

  Future<void> _determineResilientPosition() async {
    try {
      // SAFETY: Ensure the loading spinner stops within 2 seconds regardless of GPS status
      // This allows the user to see cached tiles immediately even without a signal.
      Future.delayed(const Duration(seconds: 2)).then((_) {
        if (mounted && _isLoadingMap) {
          setState(() => _isLoadingMap = false);
        }
      });

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoadingMap = false);
          return;
        }
      }

      // STEP 1: Get Last Known Position immediately (Works 100% offline)
      Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        if (mounted) {
          setState(() {
            _currentPos = LatLng(lastPos.latitude, lastPos.longitude);
            _isLoadingMap = false; // Reveal map immediately with cached tiles
          });
          _mapController.move(_currentPos, 13.0);
        }
      }

      // STEP 2: Try for a fresh lock but with a strict timeout and lower accuracy for speed
      Position freshPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Lower accuracy is much faster offline
        timeLimit: const Duration(seconds: 4),
      );

      if (mounted) {
        setState(() {
          _currentPos = LatLng(freshPos.latitude, freshPos.longitude);
          _isLoadingMap = false;
        });
        _mapController.move(_currentPos, 13.0);
      }
    } catch (e) {
      // If GPS fails or times out, stop the loader and use the last known or default
      debugPrint("CrisisGrain Map: Location fetch timed out or failed. Using fallback.");
      if (mounted) {
        setState(() => _isLoadingMap = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThematicHeader(context),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSurvivalSummaryCard(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader("Crisis Toolkit"),
                  const SizedBox(height: 16),
                  _buildToolsGrid(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader("Local Aid Map"),
                  const SizedBox(height: 16),
                  _buildResilientMapPreview(),
                  const SizedBox(height: 32),
                  _buildRequestButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThematicHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 240,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage("https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?q=80&w=800&auto=format&fit=crop"),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.9), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          top: 50,
          left: 10,
          child: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        Positioned(
          bottom: 30,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ZERO HUNGER",
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  fontSize: 12,
                ),
              ),
              const Text(
                "CrisisGrain Hub",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Protecting community food security",
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSurvivalSummaryCard(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<FoodReport>(AppConstants.boxFoodReports).listenable(),
      builder: (context, Box<FoodReport> box, _) {
        final reports = box.values.toList();
        double totalKcal = 0;
        for (var r in reports) {
          totalKcal += (r.quantity * 2500);
        }
        int dailyNeed = 5600;
        double daysLeft = dailyNeed > 0 ? (totalKcal / dailyNeed) : 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (daysLeft < 3 && daysLeft > 0) ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bolt, color: (daysLeft < 3 && daysLeft > 0) ? AppColors.error : AppColors.primary, size: 32),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("SURVIVAL ESTIMATE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      daysLeft > 0 ? "${daysLeft.toStringAsFixed(1)} Days Left" : "No Stock",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SurvivalIntelligenceScreen())),
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      children: [
        _buildToolCard(
          context,
          "Full Map",
          "Interactive viewer",
          Icons.map_rounded,
          AppColors.accent,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CrisisMapScreen())),
        ),
        _buildToolCard(
          context,
          "My Stock",
          "Manage inventory",
          Icons.inventory_2_rounded,
          Colors.green[700]!,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen())),
        ),
        _buildToolCard(
          context,
          "Survival Advisor",
          "Estimated survival tips",
          Icons.psychology_rounded,
          Colors.deepPurple,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SurvivalIntelligenceScreen())),
        ),
        _buildToolCard(
          context,
          "History",
          "Sync reports",
          Icons.history_edu_rounded,
          Colors.orange[800]!,
              () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cloud sync triggered..."))),
        ),
      ],
    );
  }

  Widget _buildToolCard(BuildContext context, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResilientMapPreview() {
    if (_cachePath == null) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPos,
              initialZoom: 13.0,
              // ENABLED INTERACTION for the preview
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.crisisgrain.app',
                tileProvider: CachedTileProvider(
                  store: FileCacheStore(_cachePath!),
                ),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPos,
                    child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoadingMap)
            Container(
              color: Colors.white70,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Button to trigger "Go to User Location" on the preview map
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton.small(
              heroTag: "map_recenter",
              backgroundColor: Colors.white,
              onPressed: () => _mapController.move(_currentPos, 14.0),
              child: const Icon(Icons.my_location, color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FoodNeedForm())),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 70),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency_outlined, size: 24),
            SizedBox(width: 12),
            Text("REQUEST EMERGENCY AID", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
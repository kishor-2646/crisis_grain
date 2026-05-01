// File: lib/features/civilian/civilian_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/camp.dart';
import '../../data/models/food_need.dart';
import 'food_need_form.dart';

class CivilianHomeScreen extends StatefulWidget {
  const CivilianHomeScreen({super.key});

  @override
  State<CivilianHomeScreen> createState() => _CivilianHomeScreenState();
}

class _CivilianHomeScreenState extends State<CivilianHomeScreen> {
  LatLng _currentPosition = const LatLng(12.9716, 77.5946);
  final MapController _mapController = MapController();
  bool _isLoadingLocation = true;
  String? _cachePath;

  @override
  void initState() {
    super.initState();
    _initMapSettings();
  }

  Future<void> _initMapSettings() async {
    await _prepareCache();
    await _determinePosition();
  }

  /// Initializes the permanent directory path for offline map storage
  Future<void> _prepareCache() async {
    final cacheDir = await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() {
        // We store the string path here
        _cachePath = '${cacheDir.path}/map_cache';
      });
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentPosition, 14.0);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure cache path is ready before rendering the map
    if (_cachePath == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.crisis_grain',
                // FIX: Pass the String path directly to FileCacheStore
                tileProvider: CachedTileProvider(
                  store: FileCacheStore(_cachePath!),
                ),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                  ),
                ],
              ),
              // Render Food Camps from local storage
              ValueListenableBuilder(
                valueListenable: Hive.box<FoodCamp>(AppConstants.boxFoodCamps).listenable(),
                builder: (context, Box<FoodCamp> box, _) {
                  return MarkerLayer(
                    markers: box.values.map((camp) {
                      // Simulated displacement for demo
                      return Marker(
                        point: LatLng(_currentPosition.latitude + 0.005, _currentPosition.longitude + 0.005),
                        child: GestureDetector(
                          onTap: () => _showCampDetails(camp),
                          child: const Icon(Icons.location_on, color: Colors.red, size: 35),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),

          // UI Layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildBottomActions(),
                ],
              ),
            ),
          ),
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          // Navigation Back or Menu Button
          IconButton(
            icon: Icon(
              Navigator.canPop(context) ? Icons.arrow_back_ios_new : Icons.menu,
              size: 20,
              color: Colors.black87,
            ),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
          const SizedBox(width: 4),
          const Icon(Icons.shield, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Crisis Map",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.accent),
            onPressed: _determinePosition,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FoodNeedForm()),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: const Text(
        "REQUEST ASSISTANCE",
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showCampDetails(FoodCamp camp) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(camp.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("📍 Location: ${camp.location}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("🍱 Meals: ${camp.mealsAvailable} remaining", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CLOSE"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
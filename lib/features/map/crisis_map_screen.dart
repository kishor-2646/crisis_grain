// File: lib/features/map/crisis_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Added for Current Location
import 'package:path_provider/path_provider.dart'; // Added for Offline Storage
import 'package:flutter_map_cache/flutter_map_cache.dart'; // Added for Offline Caching
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'dart:io';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/food_report.dart';
import '../../data/models/camp.dart';

class CrisisMapScreen extends StatefulWidget {
  const CrisisMapScreen({super.key});

  @override
  State<CrisisMapScreen> createState() => _CrisisMapScreenState();
}

class _CrisisMapScreenState extends State<CrisisMapScreen> {
  // Default to a fallback coordinate (Bengaluru)
  LatLng _mapCenter = const LatLng(12.9716, 77.5946);
  final MapController _mapController = MapController();
  bool _isLoading = true;
  String? _cachePath;

  @override
  void initState() {
    super.initState();
    _initMapLogic();
  }

  Future<void> _initMapLogic() async {
    await _prepareCacheDirectory();
    await _determineUserPosition();
  }

  /// Sets up the directory for permanent map tile storage on disk
  Future<void> _prepareCacheDirectory() async {
    final cacheDir = await getApplicationDocumentsDirectory();
    setState(() {
      _cachePath = '${cacheDir.path}/map_cache_v1';
    });
  }

  /// Requests permissions and gets current GPS position
  Future<void> _determineUserPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _handleLocationError("Location services are disabled.");
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _handleLocationError("Location permissions are denied.");
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        _mapCenter = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _mapController.move(_mapCenter, 14.0);
    } catch (e) {
      debugPrint("Map Location Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _handleLocationError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cachePath == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Relief Map"),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _determineUserPosition,
          )
        ],
      ),
      body: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: Hive.box<FoodReport>(AppConstants.boxFoodReports).listenable(),
            builder: (context, Box<FoodReport> box, _) {
              final reports = box.values.toList();

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.crisisgrain.app',
                    // DISK CACHING: This saves map tiles permanently for offline usage
                    tileProvider: CachedTileProvider(
                      store: FileCacheStore(_cachePath!),
                    ),
                  ),

                  // Relief Camp Markers (Dynamic)
                  ValueListenableBuilder(
                    valueListenable: Hive.box<FoodCamp>(AppConstants.boxFoodCamps).listenable(),
                    builder: (context, Box<FoodCamp> campBox, _) {
                      return MarkerLayer(
                        markers: campBox.values.map((camp) {
                          // Note: In demo, we place camps slightly offset from user
                          return Marker(
                            point: LatLng(_mapCenter.latitude + 0.004, _mapCenter.longitude + 0.004),
                            child: const Icon(Icons.location_on, color: AppColors.primary, size: 40),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  // Civilian Report Markers
                  MarkerLayer(
                    markers: reports.map((report) {
                      return Marker(
                        point: LatLng(report.lat, report.lng),
                        width: 45,
                        height: 45,
                        child: GestureDetector(
                          onTap: () => _showReportDetails(context, report),
                          child: Icon(Icons.place, color: AppUrgency.getColor(report.urgency), size: 45),
                        ),
                      );
                    }).toList(),
                  ),

                  // Current User Pulse
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _mapCenter,
                        child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  void _showReportDetails(BuildContext context, FoodReport report) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report.itemName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Qty: ${report.quantity} ${report.unit} • ${report.urgency}"),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () => Navigator.pop(context),
              child: const Text("Back to Map"),
            )
          ],
        ),
      ),
    );
  }
}
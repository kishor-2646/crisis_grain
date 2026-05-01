// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart'; // Added for Firebase
import 'core/constants.dart';
import 'core/sync_service.dart'; // Added for Sync Logic

// Models
import 'core/theme.dart';
import 'data/models/food_report.dart';
import 'data/models/food_need.dart';
import 'data/models/camp.dart';

// Screens
import 'features/civilian/civilian_home_screen.dart';
import 'features/ngo/ngo_home_screen.dart';
import 'features/volunteer/volunteer_home_screen.dart';

void main() async {
  // 1. Ensure Flutter is fully initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env file
  await dotenv.load(fileName: ".env");

  try {
    // 2. Initialize Firebase (The Cloud Bridge)
    // Note: Ensure you have added google-services.json (Android)
    // or GoogleService-Info.plist (iOS) to your project.
    await Firebase.initializeApp();

    // 3. Initialize Local Database (Hive)
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(FoodReportAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(FoodNeedAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FoodCampAdapter());

    // Open Local Boxes
    await Hive.openBox<FoodReport>(AppConstants.boxFoodReports);
    await Hive.openBox<FoodNeed>(AppConstants.boxFoodNeeds);
    await Hive.openBox<FoodCamp>(AppConstants.boxFoodCamps);
    await Hive.openBox(AppConstants.boxAiCache);

    // 4. Initialize the Sync Engine
    // This starts the background listener for internet connectivity
    SyncService().init();

  } catch (e) {
    debugPrint('CrisisGrain System Error: $e');
  }

  runApp(const CrisisGrainApp());
}

class CrisisGrainApp extends StatefulWidget {
  const CrisisGrainApp({super.key});

  @override
  State<CrisisGrainApp> createState() => _CrisisGrainAppState();
}

class _CrisisGrainAppState extends State<CrisisGrainApp> {
  // Tracks the current role for the multi-perspective hackathon demo
  UserRole currentRole = UserRole.civilian;

  @override
  void dispose() {
    // Clean up the sync service listener when the app is destroyed
    SyncService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrisisGrain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      // Wrapped in a Builder to provide a valid context for the Drawer Navigator
      home: Builder(
        builder: (context) => Scaffold(
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: AppColors.primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: AppColors.primary)
                      ),
                      SizedBox(height: 10),
                      Text("Role Switcher", style: TextStyle(color: Colors.white, fontSize: 18)),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text("🏠 Civilian View"),
                  selected: currentRole == UserRole.civilian,
                  onTap: () {
                    setState(() => currentRole = UserRole.civilian);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.business_outlined),
                  title: const Text("🏛️ NGO Panel"),
                  selected: currentRole == UserRole.ngo,
                  onTap: () {
                    setState(() => currentRole = UserRole.ngo);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: const Text("🚚 Volunteer Verification"),
                  selected: currentRole == UserRole.volunteer,
                  onTap: () {
                    setState(() => currentRole = UserRole.volunteer);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          appBar: AppBar(
            title: Text(_getAppBarTitle()),
            actions: [
              // Show a small sync indicator in the global AppBar
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ValueListenableBuilder<String>(
                  valueListenable: SyncService().syncStatus,
                  builder: (context, status, _) {
                    bool syncing = status.contains("Syncing");
                    return Icon(
                      syncing ? Icons.sync : Icons.cloud_done_outlined,
                      size: 16,
                      color: syncing ? Colors.white70 : Colors.white,
                    );
                  },
                ),
              )
            ],
          ),
          body: _buildBodyForRole(),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (currentRole) {
      case UserRole.civilian: return "CrisisGrain: CIVILIAN";
      case UserRole.ngo: return "CrisisGrain: NGO PANEL";
      case UserRole.volunteer: return "CrisisGrain: VOLUNTEER";
      default: return "CrisisGrain";
    }
  }

  Widget _buildBodyForRole() {
    switch (currentRole) {
      case UserRole.civilian: return const CivilianHomeScreen();
      case UserRole.ngo: return const NGOHomeScreen();
      case UserRole.volunteer: return const VolunteerHomeScreen();
      default: return const Center(child: Text("Select a role from the drawer"));
    }
  }
}
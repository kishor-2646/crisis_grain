// File: lib/core/sync_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';
import '../data/models/food_need.dart';
import '../data/models/food_report.dart';
import '../data/models/camp.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final Connectivity _connectivity = Connectivity();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<ConnectivityResult>? _subscription;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  final ValueNotifier<String> syncStatus = ValueNotifier("Ready");

  void init() {
    _firestore.settings = const Settings(persistenceEnabled: true);

    _subscription = _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      debugPrint('CrisisGrain: [CONN] Status changed to: $result');
      if (result != ConnectivityResult.none) {
        performFullSync();
      }
    });
  }

  /// NEW: Fetches all phone numbers for a specific area from the global cloud database
  Future<List<String>> getCloudPhoneNumbersForArea(String area) async {
    try {
      debugPrint('CrisisGrain: [CLOUD FETCH] Querying numbers for area: $area');

      // Query Firestore for all 'needs' where the location matches
      // Note: In a production app with thousands of records, you would use a 'where' query.
      // For this hackathon, we fetch and filter to avoid index-creation delay errors.
      final snapshot = await _firestore.collection('needs')
          .get()
          .timeout(const Duration(seconds: 10));

      final targetArea = area.toLowerCase().trim();

      final List<String> numbers = snapshot.docs
          .where((doc) {
        final data = doc.data();
        final docArea = (data['locationArea'] ?? '').toString().toLowerCase().trim();
        return docArea == targetArea;
      })
          .map((doc) => (doc.data()['phoneNumber'] ?? '').toString())
          .where((phone) => phone.isNotEmpty)
          .toSet() // Remove duplicates
          .toList();

      debugPrint('CrisisGrain: [CLOUD FETCH] Found ${numbers.length} unique recipients.');
      return numbers;
    } catch (e) {
      debugPrint('CrisisGrain: [CLOUD FETCH ERROR] $e');
      return [];
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  // ... (rest of the sync logic remains the same)
  Future<void> debugResetAllFlags() async {
    debugPrint('CrisisGrain: [DEBUG] Starting manual flag reset...');
    final needsBox = Hive.box<FoodNeed>(AppConstants.boxFoodNeeds);
    for (var i = 0; i < needsBox.length; i++) {
      final item = needsBox.getAt(i);
      if (item != null) {
        await needsBox.putAt(i, FoodNeed(
          id: item.id,
          peopleCount: item.peopleCount,
          locationArea: item.locationArea,
          phoneNumber: item.phoneNumber,
          createdAt: item.createdAt,
          isSentViaSMS: false,
          isSynced: false,
        ));
      }
    }
    debugPrint('CrisisGrain: [DEBUG] Reset ${needsBox.length} items. Starting sync...');
    performFullSync();
  }

  Future<void> performFullSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    syncStatus.value = "Syncing...";
    try {
      await _syncCollection<FoodNeed>(
        boxName: AppConstants.boxFoodNeeds,
        collectionName: 'needs',
        isSyncedCheck: (item) => item.isSentViaSMS || item.isSynced,
        toFirestore: (item) => {
          'peopleCount': item.peopleCount,
          'locationArea': item.locationArea,
          'phoneNumber': item.phoneNumber,
          'createdAt': item.createdAt.toIso8601String(),
          'type': 'NEED',
        },
        markSynced: (item) => FoodNeed(
          id: item.id,
          peopleCount: item.peopleCount,
          locationArea: item.locationArea,
          phoneNumber: item.phoneNumber,
          createdAt: item.createdAt,
          isSentViaSMS: item.isSentViaSMS,
          isSynced: true,
        ),
      );
      await _pullRemoteCamps();
      syncStatus.value = "Last sync: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    } catch (e) {
      syncStatus.value = "Sync Error";
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncCollection<T>({
    required String boxName,
    required String collectionName,
    required bool Function(T) isSyncedCheck,
    required Map<String, dynamic> Function(T) toFirestore,
    required T Function(T) markSynced,
  }) async {
    final box = Hive.box<T>(boxName);
    final unsynced = box.values.where((item) => !isSyncedCheck(item)).toList();
    for (var item in unsynced) {
      try {
        final id = (item as dynamic).id;
        await _firestore.collection(collectionName).doc(id).set(toFirestore(item)).timeout(const Duration(seconds: 15));
        final index = box.values.toList().indexOf(item);
        await box.putAt(index, markSynced(item));
      } catch (e) { debugPrint('Error syncing: $e'); }
    }
  }

  Future<void> _pullRemoteCamps() async {
    try {
      final snapshot = await _firestore.collection('camps').get().timeout(const Duration(seconds: 10));
      final box = Hive.box<FoodCamp>(AppConstants.boxFoodCamps);
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final camp = FoodCamp(
          id: doc.id,
          name: data['name'] ?? 'Camp',
          location: data['location'] ?? 'Area',
          time: data['time'] ?? 'N/A',
          mealsAvailable: data['mealsAvailable'] ?? 0,
          verificationCode: data['verificationCode'] ?? '0000',
          status: data['status'] ?? 'OPEN', contactPhone: '',
        );
        await box.put(camp.id, camp);
      }
    } catch (e) { debugPrint('Pull error: $e'); }
  }
}
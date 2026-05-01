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

  void dispose() {
    _subscription?.cancel();
  }

  /// FOR DEMO ONLY: Resets local flags so old data is treated as new
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
          phoneNumber: item.phoneNumber, // Added to fix compilation error
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
      debugPrint('CrisisGrain: >>> SYNC STARTING <<<');

      // 1. Sync Needs
      await _syncCollection<FoodNeed>(
        boxName: AppConstants.boxFoodNeeds,
        collectionName: 'needs',
        isSyncedCheck: (item) => item.isSentViaSMS || item.isSynced,
        toFirestore: (item) => {
          'peopleCount': item.peopleCount,
          'locationArea': item.locationArea,
          'phoneNumber': item.phoneNumber, // Added for cloud coordination
          'createdAt': item.createdAt.toIso8601String(),
          'type': 'NEED',
        },
        markSynced: (item) => FoodNeed(
          id: item.id,
          peopleCount: item.peopleCount,
          locationArea: item.locationArea,
          phoneNumber: item.phoneNumber, // Added to fix compilation error
          createdAt: item.createdAt,
          isSentViaSMS: item.isSentViaSMS,
          isSynced: true,
        ),
      );

      // 2. Pull Camps
      await _pullRemoteCamps();

      syncStatus.value = "Last sync: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
      debugPrint('CrisisGrain: >>> SYNC FINISHED <<<');
    } catch (e) {
      syncStatus.value = "Sync Error";
      debugPrint("CrisisGrain [FATAL] Master Error: $e");
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
    debugPrint('CrisisGrain: [CHECK] Box "$boxName" has ${box.length} total items.');

    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item != null) {
        final id = (item as dynamic).id;
        final status = isSyncedCheck(item) ? "SYNCED" : "UNSYNCED";
        debugPrint('CrisisGrain: [ITEM] ID: $id | Status: $status');
      }
    }

    final unsynced = box.values.where((item) => !isSyncedCheck(item)).toList();

    for (var item in unsynced) {
      try {
        final id = (item as dynamic).id;
        debugPrint('CrisisGrain: [PUSH] Uploading $id to collection "$collectionName"...');

        await _firestore.collection(collectionName).doc(id).set(toFirestore(item))
            .timeout(const Duration(seconds: 15));

        final index = box.values.toList().indexOf(item);
        await box.putAt(index, markSynced(item));
        debugPrint('CrisisGrain: [SUCCESS] Item $id reached the cloud.');
      } on FirebaseException catch (e) {
        debugPrint('CrisisGrain: [FIREBASE ERROR] Code: ${e.code} | Message: ${e.message}');
      } on TimeoutException {
        debugPrint('CrisisGrain: [TIMEOUT] Connection too slow to reach Firebase.');
      } catch (e) {
        debugPrint('CrisisGrain: [ERROR] Unknown failure during push: $e');
      }
    }
  }

  Future<void> _pullRemoteCamps() async {
    try {
      debugPrint('CrisisGrain: [PULL] Fetching camps from Cloud...');
      final snapshot = await _firestore.collection('camps').get().timeout(const Duration(seconds: 10));
      final box = Hive.box<FoodCamp>(AppConstants.boxFoodCamps);
      debugPrint('CrisisGrain: [PULL] Received ${snapshot.docs.length} camps.');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final camp = FoodCamp(
          id: doc.id,
          name: data['name'] ?? 'Camp',
          location: data['location'] ?? 'Area',
          time: data['time'] ?? 'N/A',
          mealsAvailable: data['mealsAvailable'] ?? 0,
          verificationCode: data['verificationCode'] ?? '0000',
          status: data['status'] ?? 'OPEN',
        );
        await box.put(camp.id, camp);
      }
    } on FirebaseException catch (e) {
      debugPrint('CrisisGrain: [FIREBASE ERROR PULL] Code: ${e.code} | Message: ${e.message}');
    } catch (e) {
      debugPrint('CrisisGrain: [PULL ERROR] $e');
    }
  }
}
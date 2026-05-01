// File: lib/features/sync/qr_sync_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hive/hive.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/food_report.dart';
import 'sync_logic.dart';

class QRSyncScreen extends StatefulWidget {
  const QRSyncScreen({super.key});

  @override
  State<QRSyncScreen> createState() => _QRSyncScreenState();
}

class _QRSyncScreenState extends State<QRSyncScreen> {
  String? qrData;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  void _prepareData() {
    final box = Hive.box<FoodReport>('foodReports');
    if (box.isNotEmpty) {
      setState(() {
        qrData = SyncLogic.encodeReports(box.values.toList());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sync & Share")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildToggleButtons(),
          Expanded(
            child: isScanning ? _buildScanner() : _buildGenerator(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code),
              label: const Text("My QR"),
              onPressed: () => setState(() => isScanning = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: !isScanning ? AppColors.primary : Colors.grey[300],
                foregroundColor: !isScanning ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Scan"),
              onPressed: () => setState(() => isScanning = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isScanning ? AppColors.primary : Colors.grey[300],
                foregroundColor: isScanning ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerator() {
    if (qrData == null) {
      return const Center(child: Text("No data to share. Add reports first."));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Other devices can scan this to sync data", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        QrImageView(
          data: qrData!,
          version: QrVersions.auto,
          size: 280.0,
          backgroundColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildScanner() {
    return MobileScanner(
      onDetect: (capture) async {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          if (barcode.rawValue != null) {
            final List<FoodReport> newReports = SyncLogic.decodeReports(barcode.rawValue!);
            if (newReports.isNotEmpty) {
              final box = Hive.box<FoodReport>('foodReports');
              for (var r in newReports) {
                await box.add(r);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Imported ${newReports.length} reports!")),
                );
                setState(() => isScanning = false);
              }
            }
          }
        }
      },
    );
  }
}
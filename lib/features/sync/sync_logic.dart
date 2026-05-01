// File: lib/features/sync/sync_logic.dart
import 'dart:convert';
import '../../data/models/food_report.dart';

class SyncLogic {
  /// Compresses current inventory into a small JSON string for QR/SMS
  static String encodeReports(List<FoodReport> reports) {
    final List<Map<String, dynamic>> data = reports.map((r) => {
      'i': r.itemName,
      'q': r.quantity,
      'u': r.urgency[0], // Only store first letter to save space
      'lat': double.parse(r.lat.toStringAsFixed(4)),
      'lng': double.parse(r.lng.toStringAsFixed(4)),
      't': r.createdAt.millisecondsSinceEpoch ~/ 1000,
    }).toList();

    return jsonEncode({'v': 1, 'd': data});
  }

  /// Decodes a QR string back into FoodReport objects
  static List<FoodReport> decodeReports(String payload) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(payload);
      final List data = decoded['d'];

      return data.map((item) {
        String urgency = "SURPLUS";
        if (item['u'] == 'L') urgency = "LOW";
        if (item['u'] == 'C') urgency = "CRITICAL";

        return FoodReport(
          id: "sync_${DateTime.now().millisecondsSinceEpoch}_${item['i']}",
          itemName: item['i'],
          quantity: (item['q'] as num).toDouble(),
          unit: "kg",
          urgency: urgency,
          lat: item['lat'],
          lng: item['lng'],
          createdAt: DateTime.fromMillisecondsSinceEpoch(item['t'] * 1000),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Generates an SMS string for a single critical report
  static String generateSMS(FoodReport report) {
    // Format: CG [ITEM] [QTY] [URGENCY_CODE] [LAT],[LNG]
    final uCode = report.urgency[0];
    return "CG ${report.itemName} ${report.quantity} $uCode ${report.lat.toStringAsFixed(4)},${report.lng.toStringAsFixed(4)}";
  }
}
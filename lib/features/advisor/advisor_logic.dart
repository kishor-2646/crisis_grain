// File: lib/features/advisor/advisor_logic.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../core/constants.dart';

class AdvisorEngine {
  static const String _apiKey = ""; // Provided at runtime by the environment

  /// Unified Interactive Method: Used by AdvisorScreen
  /// Attempts to fetch fresh data, updates cache, and returns result.
  static Future<String> getAISurvivalStrategy(List<String> items, String householdContext) async {
    return await fetchAndCacheStrategy(items, householdContext);
  }

  /// Background/Proactive Method: Used by SurvivalIntelligenceScreen
  /// Updates local storage with fresh AI insights if internet is available.
  static Future<String> fetchAndCacheStrategy(List<String> items, String householdContext) async {
    final box = Hive.box(AppConstants.boxAiCache);

    final prompt = """
    Context: Disaster Relief Food Management. 
    Household: $householdContext.
    Inventory: ${items.join(", ")}.
    Task: Provide a concise survival strategy (Eat first items, Storage hacks, Morale tip).
    Format: Bullet points.
    """;

    final result = await _callGemini(prompt);

    // Save to local cache for offline availability
    await box.put('last_strategy', result);
    await box.put('last_sync', DateTime.now().toIso8601String());

    return result;
  }

  /// Instant Offline Access: Used by AdvisorScreen
  static String getCachedOnly() {
    final box = Hive.box(AppConstants.boxAiCache);
    return box.get('last_strategy', defaultValue: "No data synced. Connect to internet to activate AI Advisor.");
  }

  /// Legacy Alias: Used by some older versions of the Intelligence screen
  static String getCachedStrategy() => getCachedOnly();

  /// Internal logic to communicate with Gemini API
  static Future<String> _callGemini(String prompt) async {
    const model = "gemini-2.5-flash-preview-09-2025";
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}]}],
          "systemInstruction": {"parts": [{"text": "You are CrisisGrain AI Survival Expert."}]}
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // FIXED: Correct null-aware map/list access syntax for Dart
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          if (content != null) {
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] ?? "Analysis completed but text missing.";
            }
          }
        }
      }
    } catch (e) {
      debugPrint("CrisisGrain AI Error: $e");
    }

    return "OFFLINE: Keep dry goods elevated and consume perishables immediately. Data will refresh when signal returns.";
  }
}
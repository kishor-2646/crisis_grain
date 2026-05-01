// File: lib/core/sms_utils.dart
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class SMSUtils {
  // Default fallback hotline
  static const String emergencyHotline = "+919000000000";

  static String generateNeedMessage(int count, String area) {
    return "CG-NEED:$count people @$area. #CrisisGrain";
  }

  static String generateCampBroadcast(String name, String loc, String code) {
    return "FOOD ALERT: $name is ACTIVE @$loc. Verification Code: $code. #CrisisGrain";
  }

  /// Launches the native SMS app with one or more recipients.
  ///
  /// NOTE: This does NOT require an internet connection. It utilizes the
  /// cellular network (telephony system) which works independently of
  /// data/Wi-Fi, making it perfect for disaster zones.
  static Future<void> launchSMS(String message, {List<String>? recipients}) async {
    // Semicolon is preferred for Android multi-SMS, Comma for iOS
    final String separator = Platform.isAndroid ? ';' : ',';

    // Join recipients if provided, otherwise fallback to the hotline
    final String target = (recipients != null && recipients.isNotEmpty)
        ? recipients.join(separator)
        : emergencyHotline;

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: target,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      // canLaunchUrl checks if an app is available to handle the 'sms' scheme
      bool canLaunch = await canLaunchUrl(smsUri);

      if (canLaunch) {
        // Mode externalApplication is required to hand over control to the
        // system's native SMS handler.
        await launchUrl(
          smsUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback for specific device variants that struggle with structured URI objects
        final String encodedMsg = Uri.encodeComponent(message);
        final String simpleUrl = "sms:$target?body=$encodedMsg";
        final Uri simpleUri = Uri.parse(simpleUrl);

        if (await canLaunchUrl(simpleUri)) {
          await launchUrl(simpleUri, mode: LaunchMode.externalApplication);
        } else {
          debugPrint("CrisisGrain: All SMS launch attempts failed for target: $target");
        }
      }
    } catch (e) {
      debugPrint("CrisisGrain: SMS Broadcast Error: $e");
    }
  }

  /// PROFESSIONAL/GOVERNMENT METHOD:
  /// Sends a request to a Cloud Gateway (like Twilio or a Govt API) to
  /// broadcast a message to ALL devices currently detected in a Geofence.
  ///
  /// This bypasses the need for the app to know individual phone numbers.
  static Future<bool> triggerGatewayBroadcast({
    required String areaName,
    required String message,
  }) async {
    debugPrint("CrisisGrain: Initializing Gateway Broadcast for $areaName...");

    try {
      // In a real scenario, this would be a POST request to a secure API:
      // await http.post(Uri.parse('https://api.govt-relief.gov/broadcast'),
      //    body: {'area': areaName, 'msg': message});

      // Simulation delay
      await Future.delayed(const Duration(seconds: 2));

      debugPrint("CrisisGrain: Gateway accepted broadcast request for area: $areaName");
      return true;
    } catch (e) {
      debugPrint("CrisisGrain: Gateway failure: $e");
      return false;
    }
  }
}
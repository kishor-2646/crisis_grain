// File: lib/core/sms_utils.dart
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class SMSUtils {
  static const String emergencyHotline = "+919000000000";

  // --- TWILIO CONFIGURATION ---
  static const String _accountSid = 'YOUR_TWILIO_ACCOUNT_SID';
  static const String _authToken = 'YOUR_TWILIO_AUTH_TOKEN';
  static const String _twilioNumber = 'YOUR_TWILIO_PHONE_NUMBER';

  static String generateNeedMessage(int count, String area) {
    return "CG-NEED:$count people @$area. #CrisisGrain";
  }

  static String generateCampBroadcast(String name, String loc, String code) {
    return "FOOD ALERT: $name is ACTIVE @$loc. Verification Code: $code. #CrisisGrain";
  }

  /// NATIVE METHOD (No Internet Required)
  static Future<void> launchSMS(String message, {List<String>? recipients}) async {
    final String separator = Platform.isAndroid ? ';' : ',';
    final String target = (recipients != null && recipients.isNotEmpty)
        ? recipients.join(separator)
        : emergencyHotline;

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: target,
      queryParameters: <String, String>{'body': message},
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("SMS Error: $e");
    }
  }

  /// PROFESSIONAL GATEWAY METHOD (Requires Internet)
  /// Updated to accept 'recipients' parameter
  static Future<bool> triggerGatewayBroadcast({
    required String areaName,
    required String message,
    required List<String> recipients,
  }) async {
    if (recipients.isEmpty) return false;

    debugPrint("CrisisGrain: Initializing Gateway for ${recipients.length} users...");
    bool allSuccessful = true;

    for (String number in recipients) {
      try {
        final response = await http.post(
          Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$_accountSid/Messages.json'),
          headers: {
            'Authorization': 'Basic ' + base64Encode(utf8.encode('$_accountSid:$_authToken')),
          },
          body: {
            'From': _twilioNumber,
            'To': number,
            'Body': message,
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 201) {
          allSuccessful = false;
        }
      } catch (e) {
        allSuccessful = false;
      }
    }
    return allSuccessful;
  }
}
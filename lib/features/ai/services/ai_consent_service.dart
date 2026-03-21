import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ai_consent_dialog.dart';

class AiConsentStatus {
  final bool given;
  final String? timestamp;
  final int? version;

  const AiConsentStatus({
    required this.given,
    required this.timestamp,
    required this.version,
  });
}

class AiConsentService {
  static const String consentVersion = '1';
  static const String _consentGivenKey = 'aiConsentGiven';
  static const String _consentTimestampKey = 'aiConsentTimestamp';
  static const String _consentVersionKey = 'aiConsentVersion';

  static Future<AiConsentStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return AiConsentStatus(
      given: prefs.getBool(_consentGivenKey) ?? false,
      timestamp: prefs.getString(_consentTimestampKey),
      version: prefs.getInt(_consentVersionKey),
    );
  }

  static Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentGivenKey, false);
    await prefs.remove(_consentTimestampKey);
    await prefs.remove(_consentVersionKey);
  }

  static Future<bool> ensureAiConsent(BuildContext context) async {
    final status = await getStatus();
    if (status.given && status.version?.toString() == consentVersion) {
      return true;
    }

    if (!context.mounted) return false;
    final agreed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AiConsentDialog(),
        ) ??
        false;

    if (!agreed) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentGivenKey, true);
    await prefs.setString(_consentTimestampKey, DateTime.now().toIso8601String());
    await prefs.setInt(_consentVersionKey, int.parse(consentVersion));
    return true;
  }
}

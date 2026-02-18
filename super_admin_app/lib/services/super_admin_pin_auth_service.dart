import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/backend_config.dart';

class SuperAdminPinAuthService {
  static bool _sessionUnlocked = false;

  static Future<bool> hasPinForUser(String uid) async {
    final data = await _postJson('superAdminHasPin', const {});
    return data['hasPin'] == true;
  }

  static Future<void> setPinForCurrentUser(String pin) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw Exception('PIN must be exactly 4 digits');
    }
    await _postJson('superAdminSetPin', {'pin': pin});
    _sessionUnlocked = true;
  }

  static Future<bool> verifyPinForCurrentUser(String pin) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) return false;
    final data = await _postJson('superAdminVerifyPin', {'pin': pin});
    final ok = data['ok'] == true;
    if (ok) _sessionUnlocked = true;
    return ok;
  }

  static bool isSessionUnlocked() => _sessionUnlocked;
  static void markPinSetupAllowed() {/* no-op (server-stored PIN) */}
  static bool canSetupPinInCurrentSession() => true;

  static Future<void> lockSession() async {
    _sessionUnlocked = false;
  }

  static Future<void> clearPinAndLock() async {
    _sessionUnlocked = false;
  }

  static Future<String?> sendPinResetOtp() async {
    final data = await _postJson('superAdminSendPinResetOtp', const {});
    final otp = (data['otp'] ?? '').toString().trim();
    return otp.isEmpty ? null : otp;
  }

  static Future<void> resetPinWithOtp({
    required String otp,
    required String newPin,
  }) async {
    await _postJson('superAdminResetPinWithOtp', {'otp': otp, 'newPin': newPin});
    _sessionUnlocked = true;
  }

  static Future<Map<String, dynamic>> _postJson(String fn, Map<String, dynamic> body) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');
    final token = await user.getIdToken(true);

    final res = await http.post(
      Uri.parse('${BackendConfig.b2ProxyBaseUrl}/$fn'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    Map<String, dynamic> data = <String, dynamic>{};
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      // ignore, handled below
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = (data['error'] ?? '').toString();
      throw Exception(msg.isNotEmpty ? msg : 'Request failed (${res.statusCode})');
    }
    return data;
  }
}

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinAuthService {
  static const _pinHashKey = 'admin_pin_hash';
  static const _pinUidKey = 'admin_pin_uid';
  static const _pinEnabledKey = 'admin_pin_enabled';

  static String _hashPin(String uid, String pin) {
    final bytes = utf8.encode('$uid::$pin');
    return sha256.convert(bytes).toString();
  }

  static Future<bool> hasPinForUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_pinEnabledKey) ?? false;
    final storedUid = prefs.getString(_pinUidKey) ?? '';
    final hash = prefs.getString(_pinHashKey) ?? '';
    return enabled && storedUid == uid && hash.isNotEmpty;
  }

  static Future<void> setPinForCurrentUser(String pin) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw Exception('PIN must be exactly 4 digits');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinUidKey, user.uid);
    await prefs.setString(_pinHashKey, _hashPin(user.uid, pin));
    await prefs.setBool(_pinEnabledKey, true);
  }

  static Future<bool> verifyPinForCurrentUser(String pin) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) return false;

    final prefs = await SharedPreferences.getInstance();
    final storedUid = prefs.getString(_pinUidKey) ?? '';
    final storedHash = prefs.getString(_pinHashKey) ?? '';
    if (storedUid != user.uid || storedHash.isEmpty) return false;

    return _hashPin(user.uid, pin) == storedHash;
  }

  static Future<void> clearPinForCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinHashKey);
    await prefs.remove(_pinUidKey);
    await prefs.remove(_pinEnabledKey);
  }
}


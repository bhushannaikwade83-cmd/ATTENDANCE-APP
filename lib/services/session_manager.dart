import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Manages user sessions, token refresh, and session timeout
class SessionManager {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static DateTime? _lastActivity;
  static const Duration _sessionTimeout = Duration(hours: 24);
  static const Duration _tokenRefreshInterval = Duration(minutes: 50);

  /// Initialize session manager
  static void initialize() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _lastActivity = DateTime.now();
        if (kDebugMode) debugPrint('✅ Session initialized for user: ${user.uid}');
      } else {
        _lastActivity = null;
        if (kDebugMode) debugPrint('🔓 Session cleared');
      }
    });

    // Periodic token refresh
    _startTokenRefreshTimer();
  }

  /// Start periodic token refresh
  static void _startTokenRefreshTimer() {
    Future.delayed(_tokenRefreshInterval, () async {
      await refreshTokenIfNeeded();
      _startTokenRefreshTimer(); // Schedule next refresh
    });
  }

  /// Refresh authentication token if needed
  static Future<void> refreshTokenIfNeeded() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Refresh the token
        await user.getIdToken(true);
        _lastActivity = DateTime.now();
        if (kDebugMode) debugPrint('🔄 Token refreshed');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Token refresh failed: $e');
    }
  }

  /// Update last activity timestamp
  static void updateActivity() {
    _lastActivity = DateTime.now();
  }

  /// Check if session is still valid
  static bool isSessionValid() {
    if (_lastActivity == null) return false;

    final now = DateTime.now();
    final difference = now.difference(_lastActivity!);

    if (difference > _sessionTimeout) {
      if (kDebugMode) debugPrint('⏰ Session expired');
      return false;
    }

    return true;
  }

  /// Check session and sign out if expired
  static Future<void> checkAndRefreshSession() async {
    if (!isSessionValid()) {
      await _auth.signOut();
      if (kDebugMode) debugPrint('🔒 Session expired, signed out');
      return;
    }

    // Refresh token if close to expiration
    await refreshTokenIfNeeded();
  }

  /// Force sign out
  static Future<void> signOut() async {
    _lastActivity = null;
    await _auth.signOut();
    if (kDebugMode) debugPrint('👋 User signed out');
  }

  /// Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return _auth.currentUser != null && isSessionValid();
  }
}

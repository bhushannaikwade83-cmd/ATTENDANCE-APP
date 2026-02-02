import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, defaultTargetPlatform, kIsWeb;

/// Service to log errors to Firestore for coder dashboard
class ErrorLogger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Log error to Firestore for coder dashboard
  /// This stores detailed error info while user sees friendly message
  static Future<void> logError({
    required dynamic error,
    required String context,
    String? userId,
    String? userEmail,
    String? instituteId,
    String? appType, // 'admin' or 'student'
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get error details
      String errorType = error.runtimeType.toString();
      String errorMessage = error.toString();
      String? errorCode;
      String? stackTrace;

      if (error is FirebaseException) {
        errorCode = error.code;
        errorMessage = error.message ?? error.toString();
      } else if (error is FirebaseAuthException) {
        errorCode = error.code;
        errorMessage = error.message ?? error.toString();
      }

      // Get stack trace if available
      try {
        stackTrace = StackTrace.current.toString();
      } catch (_) {
        stackTrace = 'Stack trace not available';
      }

      // Get current user if available
      final currentUser = FirebaseAuth.instance.currentUser;
      final loggedUserId = userId ?? currentUser?.uid;
      final loggedUserEmail = userEmail ?? currentUser?.email;

      // Create error document
      final errorData = {
        'errorType': errorType,
        'errorCode': errorCode,
        'errorMessage': errorMessage,
        'stackTrace': stackTrace,
        'context': context, // Where error occurred (e.g., 'login', 'markAttendance')
        'userId': loggedUserId,
        'userEmail': loggedUserEmail,
        'instituteId': instituteId,
        'timestamp': FieldValue.serverTimestamp(),
        'appType': appType ?? 'admin', // 'admin' or 'student'
        'deviceInfo': {
          'platform': kIsWeb ? 'web' : defaultTargetPlatform.toString(),
        },
        'additionalData': additionalData ?? {},
        'resolved': false, // For tracking if error is fixed
        'resolvedAt': null,
        'resolvedBy': null,
      };

      // Log to Firestore
      await _firestore.collection('error_logs').add(errorData);

      // Also log to console for immediate debugging
      if (kDebugMode) {
        debugPrint('🔴 ERROR LOGGED TO FIRESTORE:');
        debugPrint('   Context: $context');
        debugPrint('   Type: $errorType');
        debugPrint('   Code: $errorCode');
        debugPrint('   Message: $errorMessage');
        debugPrint('   User: $loggedUserEmail ($loggedUserId)');
        debugPrint('   Institute: $instituteId');
      }
    } catch (e) {
      // If logging fails, at least log to console
      if (kDebugMode) {
        debugPrint('❌ Failed to log error to Firestore: $e');
      }
    }
  }

  /// Mark error as resolved
  static Future<void> markErrorResolved(String errorId, String resolvedBy) async {
    try {
      await _firestore.collection('error_logs').doc(errorId).update({
        'resolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': resolvedBy,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to mark error as resolved: $e');
    }
  }

  /// Delete error log
  static Future<void> deleteError(String errorId) async {
    try {
      await _firestore.collection('error_logs').doc(errorId).delete();
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to delete error: $e');
    }
  }
}

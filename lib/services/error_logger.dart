import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, defaultTargetPlatform, kIsWeb;

/// Service to log errors to Firestore for coder dashboard
class ErrorLogger {
  /// Log error to Firestore
  static Future<void> logError({
    required dynamic error,
    required String context,
    String? userId,
    String? userEmail,
    String? instituteId,
    String? appType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      String errorType = error.runtimeType.toString();
      String errorMessage = error.toString();
      String? errorCode;

      if (error is FirebaseException) {
        errorCode = error.code;
        errorMessage = error.message ?? error.toString();
      } else if (error is Exception) {
        errorCode = error.runtimeType.toString();
      }

      String? loggedUserId = userId;
      String? loggedUserEmail = userEmail;
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          loggedUserId = userId ?? currentUser.uid;
          loggedUserEmail = userEmail ?? currentUser.email;
        }
      } catch (_) {}

      await FirebaseFirestore.instance.collection('error_logs').add({
        'errorType': errorType,
        'errorCode': errorCode,
        'errorMessage': errorMessage,
        'stackTrace': StackTrace.current.toString(),
        'context': context,
        'userId': loggedUserId,
        'userEmail': loggedUserEmail,
        'instituteId': instituteId,
        'timestamp': FieldValue.serverTimestamp(),
        'appType': appType ?? 'admin',
        'deviceInfo': {
          'platform': kIsWeb ? 'web' : defaultTargetPlatform.toString(),
        },
        'additionalData': additionalData ?? <String, dynamic>{},
        'resolved': false,
        'resolvedAt': null,
        'resolvedBy': null,
      });

      if (kDebugMode) {
        debugPrint('ERROR LOGGED: $context | $errorType | $errorCode');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to log error: $e');
      }
    }
  }

  /// Mark error as resolved
  static Future<void> markErrorResolved(String errorId, String resolvedBy) async {
    try {
      await FirebaseFirestore.instance.collection('error_logs').doc(errorId).update({
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
      await FirebaseFirestore.instance.collection('error_logs').doc(errorId).delete();
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to delete error: $e');
    }
  }
}

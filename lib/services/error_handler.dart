import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'error_logger.dart';

/// Centralized error handling service
/// Provides user-friendly messages in UI and detailed logs for developers
class ErrorHandler {
  /// Handle Firebase Auth errors
  /// Returns user-friendly message and logs detailed error for developers
  static String handleAuthError(FirebaseAuthException e, {String? context, String? instituteId, String? appType}) {
    ErrorLogger.logError(
      error: e,
      context: context ?? 'auth',
      instituteId: instituteId,
      appType: appType,
    );

    if (kDebugMode) {
      debugPrint('AUTH ERROR${context != null ? " ($context)" : ""}: ${e.code} - ${e.message}');
    }

    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'requires-recent-login':
        return 'Please log in again to continue.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Verification session expired. Request a new code.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  /// Handle Firestore errors
  /// Returns user-friendly message and logs detailed error for developers
  static String handleFirestoreError(FirebaseException e, {String? context, String? instituteId, String? appType}) {
    ErrorLogger.logError(
      error: e,
      context: context ?? 'firestore',
      instituteId: instituteId,
      appType: appType,
    );

    if (kDebugMode) {
      debugPrint('FIRESTORE ERROR${context != null ? " ($context)" : ""}: ${e.code} - ${e.message}');
    }

    switch (e.code) {
      case 'permission-denied':
        return 'Permission denied. Contact your administrator.';
      case 'unavailable':
        return 'Service unavailable. Try again in a moment.';
      case 'deadline-exceeded':
        return 'Request timed out. Try again.';
      case 'not-found':
        return 'Requested data was not found.';
      case 'already-exists':
        return 'This record already exists.';
      case 'failed-precondition':
      case 'aborted':
        return 'Operation could not be completed. Try again.';
      case 'out-of-range':
        return 'Invalid data provided.';
      case 'unimplemented':
        return 'Feature not available yet.';
      case 'internal':
        return 'Internal error. Try again later.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      case 'resource-exhausted':
        return 'Service is busy. Try again shortly.';
      default:
        return 'An error occurred while accessing data.';
    }
  }

  /// Handle general errors
  /// Returns user-friendly message and logs detailed error for developers
  static String handleError(dynamic error, {String? context, String? instituteId, String? appType}) {
    ErrorLogger.logError(
      error: error,
      context: context ?? 'general',
      instituteId: instituteId,
      appType: appType,
    );

    if (kDebugMode) {
      debugPrint('ERROR${context != null ? " ($context)" : ""}: $error');
    }

    if (error is FirebaseAuthException) {
      return handleAuthError(error, context: context, instituteId: instituteId, appType: appType);
    }
    if (error is FirebaseException) {
      return handleFirestoreError(error, context: context, instituteId: instituteId, appType: appType);
    }
    if (error is Exception) {
      return 'An error occurred: ${error.toString()}';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Format error for display in UI
  static Map<String, dynamic> formatErrorForUI(dynamic error, {String? context, String? instituteId, String? appType}) {
    final message = handleError(error, context: context, instituteId: instituteId, appType: appType);
    return {
      'success': false,
      'message': message,
      'error': error.toString(),
    };
  }
}

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'error_logger.dart';

/// Centralized error handling service
/// Provides user-friendly messages in UI and detailed logs for developers
class ErrorHandler {
  /// Handle Firebase Auth errors
  /// Returns user-friendly message and logs detailed error for developers
  static String handleAuthError(FirebaseAuthException e, {String? context, String? instituteId, String? appType}) {
    // Log error to Firestore for coder dashboard
    ErrorLogger.logError(
      error: e,
      context: context ?? 'auth',
      instituteId: instituteId,
      appType: appType,
    );

    // Log detailed error for developers (console)
    if (kDebugMode) {
      debugPrint('🔴 AUTH ERROR${context != null ? " ($context)" : ""}:');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      debugPrint('   Email: ${e.email}');
      debugPrint('   Credential: ${e.credential}');
      debugPrint('   Stack: ${StackTrace.current}');
    }

    // Return user-friendly messages
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or create a new account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or use "Forgot Password" to reset.';
      case 'invalid-email':
        return 'Invalid email format. Please enter a valid email address (e.g., user@example.com).';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email or try logging in.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters with a mix of letters and numbers.';
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes before trying again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'requires-recent-login':
        return 'Please log out and log in again to perform this action.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please check and try again.';
      case 'invalid-verification-id':
        return 'Verification session expired. Please request a new code.';
      default:
        // Log unknown errors for debugging
        if (kDebugMode) {
          debugPrint('⚠️ UNKNOWN AUTH ERROR: ${e.code} - ${e.message}');
        }
        return 'Authentication failed. Please try again. If the problem persists, contact support.';
    }
  }

  /// Handle Firestore errors
  /// Returns user-friendly message and logs detailed error for developers
  static String handleFirestoreError(FirebaseException e, {String? context, String? instituteId, String? appType}) {
    // Log error to Firestore for coder dashboard
    ErrorLogger.logError(
      error: e,
      context: context ?? 'firestore',
      instituteId: instituteId,
      appType: appType,
    );

    // Log detailed error for developers (console)
    if (kDebugMode) {
      debugPrint('🔴 FIRESTORE ERROR${context != null ? " ($context)" : ""}:');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      debugPrint('   Stack: ${StackTrace.current}');
    }

    // Return user-friendly messages
    switch (e.code) {
      case 'permission-denied':
        return 'Permission denied. You don\'t have access to perform this action. Please contact your administrator.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please check your internet connection and try again.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your internet connection and try again.';
      case 'not-found':
        return 'The requested data was not found.';
      case 'already-exists':
        return 'This record already exists.';
      case 'failed-precondition':
        return 'Operation cannot be completed. Please try again.';
      case 'aborted':
        return 'Operation was cancelled. Please try again.';
      case 'out-of-range':
        return 'Invalid data provided. Please check your input.';
      case 'unimplemented':
        return 'This feature is not yet available.';
      case 'internal':
        return 'An internal error occurred. Please try again later.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      case 'resource-exhausted':
        return 'Service is temporarily overloaded. Please try again in a moment.';
      default:
        if (kDebugMode) {
          debugPrint('⚠️ UNKNOWN FIRESTORE ERROR: ${e.code} - ${e.message}');
        }
        return 'An error occurred while accessing data. Please try again.';
    }
  }

  /// Handle general errors
  /// Returns user-friendly message and logs detailed error for developers
  static String handleError(dynamic error, {String? context, String? instituteId, String? appType}) {
    // Log error to Firestore for coder dashboard
    ErrorLogger.logError(
      error: error,
      context: context ?? 'general',
      instituteId: instituteId,
      appType: appType,
    );

    // Log detailed error for developers (console)
    if (kDebugMode) {
      debugPrint('🔴 ERROR${context != null ? " ($context)" : ""}:');
      debugPrint('   Type: ${error.runtimeType}');
      debugPrint('   Error: $error');
      if (error is FirebaseException) {
        debugPrint('   Code: ${error.code}');
        debugPrint('   Message: ${error.message}');
      }
      debugPrint('   Stack: ${StackTrace.current}');
    }

    // Handle specific error types
    if (error is FirebaseAuthException) {
      return handleAuthError(error, context: context);
    } else if (error is FirebaseException) {
      return handleFirestoreError(error, context: context);
    } else if (error is Exception) {
      return 'An error occurred: ${error.toString()}';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Format error for display in UI
  /// Shows user-friendly message with optional action
  /// Errors are automatically logged to Firestore for coder dashboard
  static Map<String, dynamic> formatErrorForUI(dynamic error, {String? context, String? instituteId, String? appType}) {
    final message = handleError(error, context: context, instituteId: instituteId, appType: appType);
    return {
      'success': false,
      'message': message,
      'error': error.toString(), // Keep original error for debugging (not shown to user)
    };
  }
}

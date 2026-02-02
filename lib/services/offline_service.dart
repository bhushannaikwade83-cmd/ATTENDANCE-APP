import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflineService {
  static const String _pendingAttendanceKey = 'pending_attendance';
  static const String _pendingPhotosKey = 'pending_photos';

  // Save attendance to local storage (for offline mode)
  static Future<void> savePendingAttendance(Map<String, dynamic> attendanceData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingList = prefs.getStringList(_pendingAttendanceKey) ?? [];
      pendingList.add(jsonEncode(attendanceData));
      await prefs.setStringList(_pendingAttendanceKey, pendingList);
      if (kDebugMode) debugPrint('💾 Saved attendance to offline storage');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error saving offline attendance: $e');
    }
  }

  // Get all pending attendance records
  static Future<List<Map<String, dynamic>>> getPendingAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingList = prefs.getStringList(_pendingAttendanceKey) ?? [];
      return pendingList.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading offline attendance: $e');
      return [];
    }
  }

  // Sync pending attendance to Firestore
  static Future<void> syncPendingAttendance(String instituteId) async {
    try {
      final pendingList = await getPendingAttendance();
      if (pendingList.isEmpty) return;

      if (kDebugMode) debugPrint('🔄 Syncing ${pendingList.length} pending attendance records...');

      final firestore = FirebaseFirestore.instance;
      int successCount = 0;
      int failCount = 0;

      for (var attendanceData in pendingList) {
        try {
          final docId = attendanceData['docId'] as String?;
          if (docId == null) continue;

          await firestore
              .collection('institutes')
              .doc(instituteId)
              .collection('attendance')
              .doc(docId)
              .set(attendanceData, SetOptions(merge: true));

          successCount++;
        } catch (e) {
          if (kDebugMode) debugPrint('❌ Error syncing attendance: $e');
          failCount++;
        }
      }

      // Remove successfully synced records
      if (successCount > 0) {
        await _removeSyncedAttendance(successCount);
        if (kDebugMode) debugPrint('✅ Synced $successCount attendance records');
      }

      if (failCount > 0) {
        if (kDebugMode) debugPrint('⚠️ Failed to sync $failCount records');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error syncing pending attendance: $e');
    }
  }

  // Remove synced attendance from local storage
  static Future<void> _removeSyncedAttendance(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingList = prefs.getStringList(_pendingAttendanceKey) ?? [];
      if (pendingList.length > count) {
        pendingList.removeRange(0, count);
        await prefs.setStringList(_pendingAttendanceKey, pendingList);
      } else {
        await prefs.remove(_pendingAttendanceKey);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error removing synced attendance: $e');
    }
  }

  // Clear all pending attendance
  static Future<void> clearPendingAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingAttendanceKey);
      if (kDebugMode) debugPrint('🗑️ Cleared all pending attendance');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error clearing pending attendance: $e');
    }
  }

  // Check if there are pending records
  static Future<bool> hasPendingAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingList = prefs.getStringList(_pendingAttendanceKey) ?? [];
      return pendingList.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get count of pending records
  static Future<int> getPendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingList = prefs.getStringList(_pendingAttendanceKey) ?? [];
      return pendingList.length;
    } catch (e) {
      return 0;
    }
  }
}

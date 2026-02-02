import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'validation_service.dart';

class BatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new batch
  /// Batch structure: { name, year, timing, subjects: [list of subjects] }
  Future<Map<String, dynamic>> createBatch({
    required String instituteId,
    required String batchName,
    required String year,
    required String timing,
    required List<String> subjects,
  }) async {
    try {
      // Validate inputs
      if (batchName.isEmpty) {
        return {'success': false, 'message': 'Batch name is required'};
      }
      if (year.isEmpty) {
        return {'success': false, 'message': 'Year is required'};
      }
      if (timing.isEmpty) {
        return {'success': false, 'message': 'Timing is required'};
      }
      if (subjects.isEmpty) {
        return {'success': false, 'message': 'At least one subject is required'};
      }

      // Sanitize inputs
      batchName = ValidationService.sanitizeInput(batchName);
      year = ValidationService.sanitizeInput(year);
      timing = ValidationService.sanitizeInput(timing);

      // Check if batch already exists (case-insensitive)
      final normalizedBatchName = ValidationService.normalizeBatchName(batchName);
      final existingBatches = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .get();

      for (var doc in existingBatches.docs) {
        final existingData = doc.data();
        final existingName = existingData['name'] as String? ?? '';
        final existingYear = existingData['year'] as String? ?? '';
        
        if (existingYear.toLowerCase() == year.toLowerCase() &&
            ValidationService.normalizeBatchName(existingName) == normalizedBatchName) {
          return {
            'success': false,
            'message': 'Batch "$existingName" already exists for year $year'
          };
        }
      }

      // Create batch document
      final batchData = {
        'name': batchName,
        'year': year,
        'timing': timing,
        'subjects': subjects,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid ?? 'admin',
        'studentCount': 0,
      };

      await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .add(batchData);

      if (kDebugMode) {
        debugPrint('✅ Batch created: $batchName (Year: $year)');
      }

      return {'success': true, 'message': 'Batch created successfully'};
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error creating batch: $e');
      return {'success': false, 'message': 'Error creating batch: ${e.toString()}'};
    }
  }

  /// Get all batches for an institute
  Future<List<Map<String, dynamic>>> getBatches(String instituteId) async {
    try {
      final snapshot = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .orderBy('year')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'year': data['year'] ?? '',
          'timing': data['timing'] ?? '',
          'subjects': List<String>.from(data['subjects'] ?? []),
          'studentCount': data['studentCount'] ?? 0,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting batches: $e');
      return [];
    }
  }

  /// Get batches filtered by year
  Future<List<Map<String, dynamic>>> getBatchesByYear(
      String instituteId, String year) async {
    try {
      final snapshot = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .where('year', isEqualTo: year)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'year': data['year'] ?? '',
          'timing': data['timing'] ?? '',
          'subjects': List<String>.from(data['subjects'] ?? []),
          'studentCount': data['studentCount'] ?? 0,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting batches by year: $e');
      return [];
    }
  }

  /// Update batch
  Future<Map<String, dynamic>> updateBatch({
    required String instituteId,
    required String batchId,
    String? batchName,
    String? year,
    String? timing,
    List<String>? subjects,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (batchName != null) {
        updateData['name'] = ValidationService.sanitizeInput(batchName);
      }
      if (year != null) {
        updateData['year'] = ValidationService.sanitizeInput(year);
      }
      if (timing != null) {
        updateData['timing'] = ValidationService.sanitizeInput(timing);
      }
      if (subjects != null) {
        updateData['subjects'] = subjects;
      }

      if (updateData.isEmpty) {
        return {'success': false, 'message': 'No fields to update'};
      }

      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .doc(batchId)
          .update(updateData);

      return {'success': true, 'message': 'Batch updated successfully'};
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error updating batch: $e');
      return {'success': false, 'message': 'Error updating batch: ${e.toString()}'};
    }
  }

  /// Delete batch
  Future<Map<String, dynamic>> deleteBatch(
      String instituteId, String batchId) async {
    try {
      // Check if batch has students
      final batchDoc = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .doc(batchId)
          .get();

      if (batchDoc.exists) {
        final studentCount = batchDoc.data()?['studentCount'] ?? 0;
        if (studentCount > 0) {
          return {
            'success': false,
            'message': 'Cannot delete batch with $studentCount students. Please remove students first.'
          };
        }
      }

      await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .doc(batchId)
          .delete();

      return {'success': true, 'message': 'Batch deleted successfully'};
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error deleting batch: $e');
      return {'success': false, 'message': 'Error deleting batch: ${e.toString()}'};
    }
  }

  /// Increment student count when student is added to batch
  Future<void> incrementStudentCount(String instituteId, String batchId) async {
    try {
      await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .doc(batchId)
          .update({
        'studentCount': FieldValue.increment(1),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error incrementing student count: $e');
    }
  }

  /// Decrement student count when student is removed from batch
  Future<void> decrementStudentCount(String instituteId, String batchId) async {
    try {
      await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .doc(batchId)
          .update({
        'studentCount': FieldValue.increment(-1),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error decrementing student count: $e');
    }
  }

  /// Get batch statistics (student count, attendance rate)
  Future<Map<String, dynamic>> getBatchStatistics(String instituteId, String batchId) async {
    try {
      // Get batch info
      final batchDoc = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .doc(batchId)
          .get();

      if (!batchDoc.exists) {
        return {'success': false, 'message': 'Batch not found'};
      }

      final batchData = batchDoc.data()!;
      final studentCount = batchData['studentCount'] ?? 0;

      // Get attendance records for this batch
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Get all students in this batch
      final studentsSnapshot = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('students')
          .where('batchId', isEqualTo: batchId)
          .get();

      final studentIds = studentsSnapshot.docs.map((doc) => doc.data()['userId'] as String? ?? '').where((id) => id.isNotEmpty).toList();

      if (studentIds.isEmpty) {
        return {
          'success': true,
          'studentCount': studentCount,
          'attendanceRate': 0.0,
          'totalAttendance': 0,
          'expectedAttendance': 0,
        };
      }

      // Get attendance records for this month
      final attendanceSnapshot = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('attendance')
          .where('rollNumber', whereIn: studentIds.length > 10 ? studentIds.take(10).toList() : studentIds)
          .get();

      // Calculate attendance rate
      final totalAttendance = attendanceSnapshot.docs.length;
      final daysInMonth = endOfMonth.day;
      final expectedAttendance = studentCount * daysInMonth;
      final attendanceRate = expectedAttendance > 0 ? (totalAttendance / expectedAttendance * 100) : 0.0;

      return {
        'success': true,
        'studentCount': studentCount,
        'attendanceRate': attendanceRate.clamp(0.0, 100.0),
        'totalAttendance': totalAttendance,
        'expectedAttendance': expectedAttendance,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting batch statistics: $e');
      return {'success': false, 'message': 'Error calculating statistics: ${e.toString()}'};
    }
  }

  /// Duplicate a batch with all subjects
  Future<Map<String, dynamic>> duplicateBatch({
    required String instituteId,
    required String batchId,
    String? newBatchName,
    String? newYear,
  }) async {
    try {
      // Get original batch
      final batchDoc = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .doc(batchId)
          .get();

      if (!batchDoc.exists) {
        return {'success': false, 'message': 'Batch not found'};
      }

      final batchData = batchDoc.data()!;
      final originalName = batchData['name'] as String? ?? '';
      final originalYear = batchData['year'] as String? ?? '';
      final timing = batchData['timing'] as String? ?? '';
      final subjects = List<String>.from(batchData['subjects'] ?? []);

      // Create new batch name if not provided
      final finalBatchName = newBatchName ?? '$originalName (Copy)';
      final finalYear = newYear ?? originalYear;

      // Check if duplicate batch already exists
      final normalizedBatchName = ValidationService.normalizeBatchName(finalBatchName);
      final existingBatches = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .get();

      for (var doc in existingBatches.docs) {
        final existingData = doc.data();
        final existingName = existingData['name'] as String? ?? '';
        final existingYear = existingData['year'] as String? ?? '';
        
        if (existingYear.toLowerCase() == finalYear.toLowerCase() &&
            ValidationService.normalizeBatchName(existingName) == normalizedBatchName) {
          return {
            'success': false,
            'message': 'Batch "$finalBatchName" already exists for year $finalYear'
          };
        }
      }

      // Create duplicate batch
      final result = await createBatch(
        instituteId: instituteId,
        batchName: finalBatchName,
        year: finalYear,
        timing: timing,
        subjects: subjects,
      );

      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error duplicating batch: $e');
      return {'success': false, 'message': 'Error duplicating batch: ${e.toString()}'};
    }
  }
}

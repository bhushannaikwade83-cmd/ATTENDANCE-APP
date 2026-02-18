import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'validation_service.dart';

class BatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> createBatch({
    required String instituteId,
    required String batchName,
    required String year,
    required String timing,
    required List<String> subjects,
  }) async {
    try {
      if (batchName.isEmpty) return {'success': false, 'message': 'Batch name is required'};
      if (year.isEmpty) return {'success': false, 'message': 'Year is required'};
      if (timing.isEmpty) return {'success': false, 'message': 'Timing is required'};
      if (subjects.isEmpty) return {'success': false, 'message': 'At least one subject is required'};

      final cleanName = ValidationService.sanitizeInput(batchName);
      final cleanYear = ValidationService.sanitizeInput(year);
      final cleanTiming = ValidationService.sanitizeInput(timing);
      final normalizedBatchName = ValidationService.normalizeBatchName(cleanName);

      final existing = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .get();

      for (final doc in existing.docs) {
        final data = doc.data();
        final existingName = (data['name'] ?? '').toString();
        final existingYear = (data['year'] ?? '').toString();
        if (existingYear.toLowerCase() == cleanYear.toLowerCase() &&
            ValidationService.normalizeBatchName(existingName) == normalizedBatchName) {
          return {
            'success': false,
            'message': 'Batch "$existingName" already exists for year $cleanYear',
          };
        }
      }

      await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .add({
        'name': cleanName,
        'year': cleanYear,
        'timing': cleanTiming,
        'subjects': subjects,
        'instituteId': instituteId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'studentCount': 0,
      });

      return {'success': true, 'message': 'Batch created successfully'};
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating batch: $e');
      return {'success': false, 'message': 'Error creating batch: ${e.toString()}'};
    }
  }

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
          'subjects': List<String>.from(data['subjects'] ?? const []),
          'studentCount': data['studentCount'] ?? 0,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting batches: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBatchesByYear(String instituteId, String year) async {
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
          'subjects': List<String>.from(data['subjects'] ?? const []),
          'studentCount': data['studentCount'] ?? 0,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting batches by year: $e');
      return [];
    }
  }

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
      if (batchName != null) updateData['name'] = ValidationService.sanitizeInput(batchName);
      if (year != null) updateData['year'] = ValidationService.sanitizeInput(year);
      if (timing != null) updateData['timing'] = ValidationService.sanitizeInput(timing);
      if (subjects != null) updateData['subjects'] = subjects;
      if (updateData.isEmpty) return {'success': false, 'message': 'No fields to update'};
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .doc(batchId)
          .update(updateData);

      return {'success': true, 'message': 'Batch updated successfully'};
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating batch: $e');
      return {'success': false, 'message': 'Error updating batch: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteBatch(String instituteId, String batchId) async {
    try {
      final batchDoc = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .doc(batchId)
          .get();

      final studentCount = (batchDoc.data()?['studentCount'] ?? 0) as int;
      if (studentCount > 0) {
        return {
          'success': false,
          'message': 'Cannot delete batch with $studentCount students. Please remove students first.'
        };
      }

      await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .doc(batchId)
          .delete();

      return {'success': true, 'message': 'Batch deleted successfully'};
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting batch: $e');
      return {'success': false, 'message': 'Error deleting batch: ${e.toString()}'};
    }
  }

  Future<void> incrementStudentCount(String instituteId, String batchId) async {
    await _firestore
        .collection('institutes')
        .doc(instituteId)
        .collection('batches')
        .doc(batchId)
        .update({'studentCount': FieldValue.increment(1)});
  }

  Future<void> decrementStudentCount(String instituteId, String batchId) async {
    await _firestore
        .collection('institutes')
        .doc(instituteId)
        .collection('batches')
        .doc(batchId)
        .update({'studentCount': FieldValue.increment(-1)});
  }

  Future<Map<String, dynamic>> getBatchStatistics(String instituteId, String batchId) async {
    try {
      final batchDoc = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .doc(batchId)
          .get();

      final studentCount = (batchDoc.data()?['studentCount'] ?? 0) as int;
      final studentsSnapshot = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('students')
          .where('batchId', isEqualTo: batchId)
          .get();

      final studentIds = studentsSnapshot.docs
          .map((d) => (d.data()['userId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      final attendanceSnapshot = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('attendance')
          .get();

      final totalAttendance = attendanceSnapshot.docs.where((d) {
        final roll = (d.data()['rollNumber'] ?? '').toString();
        return studentIds.contains(roll);
      }).length;

      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final expectedAttendance = studentCount * daysInMonth;
      final attendanceRate = expectedAttendance > 0
          ? (totalAttendance / expectedAttendance * 100)
          : 0.0;

      return {
        'success': true,
        'studentCount': studentCount,
        'attendanceRate': attendanceRate,
        'totalAttendance': totalAttendance,
        'expectedAttendance': expectedAttendance,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error getting statistics: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>?> getBatchById(String instituteId, String batchId) async {
    try {
      final doc = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('batches')
          .doc(batchId)
          .get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'year': data['year'] ?? '',
        'timing': data['timing'] ?? '',
        'subjects': List<String>.from(data['subjects'] ?? const []),
        'studentCount': data['studentCount'] ?? 0,
      };
    } catch (_) {
      return null;
    }
  }

  Future<bool> batchExists(String instituteId, String batchName, String year) async {
    final normalized = ValidationService.normalizeBatchName(batchName);
    final docs = await getBatchesByYear(instituteId, year);
    return docs.any((b) => ValidationService.normalizeBatchName((b['name'] ?? '').toString()) == normalized);
  }
}

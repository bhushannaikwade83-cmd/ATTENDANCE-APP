import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/backend_config.dart';

class SuperAdminService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<({bool allowed, String reason})> checkAccess(String uid) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final email = currentUser?.email?.trim().toLowerCase();
      if (email == 'digitrixmedia05@gmail.com') {
        final coderRef = _db.collection('coders').doc(uid);
        // Best-effort bootstrap. If Firestore rules in the deployed project block
        // this read/write, don't prevent login for debug builds.
        try {
          final coderDoc = await coderRef.get();
          await coderRef.set({
            'uid': uid,
            'email': email,
            'role': 'super_admin',
            'isSuperAdmin': true,
            if (!coderDoc.exists) 'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {
          if (kDebugMode) {
            return (allowed: true, reason: 'bootstrap_super_admin_firestore_denied');
          }
          rethrow;
        }
        return (allowed: true, reason: 'bootstrap_super_admin');
      }

      final coderDoc = await _db.collection('coders').doc(uid).get();
      if (coderDoc.exists) {
        final data = coderDoc.data() ?? <String, dynamic>{};
        final role = (data['role'] ?? '').toString().toLowerCase();
        final allowed =
            data['isSuperAdmin'] == true || role == 'super_admin' || role == 'superadmin';
        if (allowed) {
          return (allowed: true, reason: 'coder_super_admin');
        }
      }

      // Optional fallback: allow users in main_admins collection as super admins.
      final mainAdminDoc =
          await _db.collection('main_admins').doc(uid).get();
      if (mainAdminDoc.exists) {
        return (allowed: true, reason: 'main_admin');
      }

      return (
        allowed: false,
        reason:
            'No super-admin role found. Add doc in coders/{uid} with isSuperAdmin=true or role=super_admin.',
      );
    } catch (e) {
      if (kDebugMode) {
        final email = FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase();
        if (email == 'digitrixmedia05@gmail.com') {
          return (allowed: true, reason: 'bootstrap_super_admin_accesscheck_failed');
        }
      }
      return (
        allowed: false,
        reason: 'Access check failed: $e',
      );
    }
  }

  static Future<bool> isSuperAdmin(String uid) async {
    final result = await checkAccess(uid);
    return result.allowed;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> institutesStream() {
    return _db.collection('institutes').orderBy('name').snapshots();
  }

  static Future<void> createInstitute({
    required String instituteId,
    required String name,
    String? instituteCode,
    String? city,
    String? state,
  }) async {
    final id = instituteId.trim();
    if (id.isEmpty) {
      throw Exception('Institute ID is required.');
    }

    final idDoc = await _db.collection('institutes').doc(id).get();
    if (idDoc.exists) {
      throw Exception('Institute ID already exists.');
    }

    final code = (instituteCode ?? '').trim();
    if (code.isNotEmpty) {
      final codeDoc = await _db
          .collection('institutes')
          .where('instituteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (codeDoc.docs.isNotEmpty) {
        throw Exception('Institute code already exists.');
      }
    }

    await _db.collection('institutes').doc(id).set({
      'instituteId': id,
      'instituteCode': code,
      'name': name.trim(),
      'city': (city ?? '').trim(),
      'state': (state ?? '').trim(),
      'isActive': true,
      'isDeleted': false,
      'userCount': 0,
      'studentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updateInstitute({
    required String instituteId,
    required String name,
    String? instituteCode,
    String? city,
    String? state,
    bool? isActive,
  }) async {
    final code = (instituteCode ?? '').trim();
    if (code.isNotEmpty) {
      final codeDoc = await _db
          .collection('institutes')
          .where('instituteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (codeDoc.docs.isNotEmpty && codeDoc.docs.first.id != instituteId) {
        throw Exception('Institute code already used by another institute.');
      }
    }

    final updateData = <String, dynamic>{
      'name': name.trim(),
      'instituteCode': code,
      'city': (city ?? '').trim(),
      'state': (state ?? '').trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isActive != null) {
      updateData['isActive'] = isActive;
    }

    await _db.collection('institutes').doc(instituteId).set(updateData, SetOptions(merge: true));
  }

  static Future<void> softDeleteInstitute(String instituteId) async {
    await _db.collection('institutes').doc(instituteId).set({
      'isDeleted': true,
      'isActive': false,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> hardDeleteInstitute(String instituteId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('You are not logged in.');

    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) throw Exception('Missing Firebase token.');

    final response = await http.post(
      Uri.parse('${BackendConfig.b2ProxyBaseUrl}/hardDeleteInstitute'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'instituteId': instituteId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Hard delete failed (${response.statusCode}): ${response.body}');
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> pendingApprovalsStream() {
    return _db.collection('users').where('status', isEqualTo: 'pending').snapshots();
  }

  static Future<void> setRegistrationStatus({
    required String userUid,
    required String instituteId,
    required bool approved,
    String? rejectionReason,
  }) async {
    var resolvedInstituteId = instituteId.trim();
    if (resolvedInstituteId.isEmpty) {
      final topDoc = await _db.collection('users').doc(userUid).get();
      final topData = topDoc.data() ?? <String, dynamic>{};
      resolvedInstituteId = (topData['instituteId'] ?? '').toString().trim();
    }
    if (resolvedInstituteId.isEmpty) {
      throw Exception('Cannot review user: instituteId not found.');
    }

    final status = approved ? 'active' : 'rejected';
    final updatePayload = <String, dynamic>{
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': approved ? FieldValue.delete() : (rejectionReason ?? 'Rejected'),
      'approvedAt': approved ? FieldValue.serverTimestamp() : FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final topUserRef = _db.collection('users').doc(userUid);
    final instituteUserRef =
        _db.collection('institutes').doc(resolvedInstituteId).collection('users').doc(userUid);

    await _db.runTransaction((tx) async {
      tx.set(topUserRef, updatePayload, SetOptions(merge: true));
      tx.set(instituteUserRef, updatePayload, SetOptions(merge: true));
    });
  }
}

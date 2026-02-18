import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_fs;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:math';
import 'error_handler.dart';
import 'validation_service.dart';

class AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final fb_fs.FirebaseFirestore _firestore = fb_fs.FirebaseFirestore.instance;

  // Store OTPs temporarily (in production, use better solution)
  final Map<String, String> _otpStorage = {};
  final Map<String, String> _registrationOtpStorage = {}; // For registration OTP
  final Map<String, String> _verificationIdStorage = {}; // Store verification IDs

  // ========== REGISTRATION METHODS ==========

  /// Register a new ADMIN
  Future<Map<String, dynamic>> registerAdmin({
    required String email,
    required String password,
    required String name,
    required String adminId,
  }) async {
    try {
      final emailError = ValidationService.validateEmail(email);
      if (emailError != null) return {'success': false, 'message': emailError};
      final passwordError = ValidationService.validatePassword(password, isRegistration: true);
      if (passwordError != null) return {'success': false, 'message': passwordError};
      final nameError = ValidationService.validateName(name);
      if (nameError != null) return {'success': false, 'message': nameError};

      final cred = await _auth.createUserWithEmailAndPassword(
        email: ValidationService.sanitizeInput(email),
        password: password,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'userId': ValidationService.sanitizeInput(adminId),
        'name': ValidationService.sanitizeInput(name),
        'email': ValidationService.sanitizeInput(email),
        'role': 'admin',
        'createdAt': fb_fs.FieldValue.serverTimestamp(),
        'lastLogin': null,
      }, fb_fs.SetOptions(merge: true));

      await _auth.signOut();
      return {'success': true, 'message': 'Admin created successfully'};
    } on fb_auth.FirebaseAuthException catch (e) {
      return {'success': false, 'message': ErrorHandler.handleAuthError(e)};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ========== MANUAL ENTRY (NO PHONE) ==========

  /// Manually add a student (For students without phones)
  /// They will exist in the database but cannot login to the app.
  Future<Map<String, dynamic>> addStudentManually({
    required String name,
    required String rollNumber,
    required String year,
    required String contactNo,
    String? batchId,
    String? batchName,
    String? batchTiming,
    String? subject,
    List<String>? subjects,
    String? instituteId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      String? resolvedInstituteId = instituteId;
      if ((resolvedInstituteId == null || resolvedInstituteId.isEmpty) && currentUser != null) {
        final insts = await _firestore.collection('institutes').limit(100).get();
        for (final inst in insts.docs) {
          final u = await _firestore
              .collection('institutes')
              .doc(inst.id)
              .collection('users')
              .doc(currentUser.uid)
              .get();
          if (u.exists) {
            resolvedInstituteId = inst.id;
            break;
          }
        }
      }

      if (resolvedInstituteId == null || resolvedInstituteId.isEmpty) {
        return {'success': false, 'message': 'Institute ID not found for current user'};
      }

      final docRef = _firestore
          .collection('institutes')
          .doc(resolvedInstituteId)
          .collection('students')
          .doc();

      await docRef.set({
        'uid': docRef.id,
        'name': ValidationService.sanitizeInput(name),
        'userId': ValidationService.sanitizeInput(rollNumber),
        'year': ValidationService.sanitizeInput(year),
        'contactNo': ValidationService.sanitizeInput(contactNo),
        'batchId': batchId,
        'batchName': batchName,
        'batchTiming': batchTiming,
        'subject': subject,
        'subjects': subjects ?? (subject == null ? [] : [subject]),
        'instituteId': resolvedInstituteId,
        'hasDevice': false,
        'role': 'student',
        'status': 'approved',
        'createdAt': fb_fs.FieldValue.serverTimestamp(),
      }, fb_fs.SetOptions(merge: true));

      await _firestore.collection('institutes').doc(resolvedInstituteId).set({
        'studentCount': fb_fs.FieldValue.increment(1),
        'lastStudentAdded': fb_fs.FieldValue.serverTimestamp(),
      }, fb_fs.SetOptions(merge: true));

      return {
        'success': true,
        'message': 'Student added successfully',
        'studentId': docRef.id,
        'instituteId': resolvedInstituteId,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ========== LOGIN METHODS (UPDATED) ==========

  /// Sign in with EMAIL and password (supports both old and new institute-based structure)
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final fb_auth.UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      fb_fs.QuerySnapshot? query;
      try {
        query = await _firestore
            .collectionGroup('users')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
      } catch (_) {
        // Some rule sets block collectionGroup queries. Fallback to /users/{uid}.
        query = null;
      }

      Map<String, dynamic>? userData;
      String? instituteId;
      String? instituteName;
      fb_fs.DocumentReference<Map<String, dynamic>>? userRef;

      if (query != null && query.docs.isNotEmpty) {
        final doc = query.docs.first;
        userData = doc.data() as Map<String, dynamic>;
        userRef = doc.reference as fb_fs.DocumentReference<Map<String, dynamic>>;
        instituteId = (userData['instituteId'] ?? '').toString();
        instituteName = (userData['instituteName'] ?? '').toString();
      } else {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          userData = doc.data();
          userRef = doc.reference;
          instituteId = (userData?['instituteId'] ?? '').toString();
          instituteName = (userData?['instituteName'] ?? '').toString();
        } else {
          // Final fallback: scan institutes and read users/{uid} directly.
          try {
            final insts = await _firestore.collection('institutes').limit(200).get();
            for (final inst in insts.docs) {
              final u = await _firestore
                  .collection('institutes')
                  .doc(inst.id)
                  .collection('users')
                  .doc(uid)
                  .get();
              if (u.exists) {
                userData = u.data();
                userRef = u.reference;
                instituteId = (userData?['instituteId'] ?? inst.id).toString();
                instituteName = (userData?['instituteName'] ?? inst.data()['name'] ?? inst.id).toString();
                // Backfill top-level /users profile to avoid future permission issues.
                await _firestore.collection('users').doc(uid).set({
                  ...(userData ?? <String, dynamic>{}),
                  'uid': uid,
                  'instituteId': instituteId,
                  'instituteName': instituteName,
                  'role': (userData?['role'] ?? 'admin').toString(),
                }, fb_fs.SetOptions(merge: true));
                break;
              }
            }
          } catch (_) {}
        }
      }

      if (userData == null) {
        await _auth.signOut();
        return {'success': false, 'message': 'User profile not found in Firebase.'};
      }

      final role = (userData['role'] ?? '').toString();
      if (role != 'admin') {
        await _auth.signOut();
        return {'success': false, 'message': 'Access denied. Admin only.'};
      }

      final status = (userData['status'] ?? 'active').toString().toLowerCase();
      if (status != 'active' && status != 'approved') {
        await _auth.signOut();
        if (status == 'pending') {
          return {
            'success': false,
            'message': 'Your registration is pending super admin approval.',
          };
        }
        return {
          'success': false,
          'message': 'Your account is not active. Contact super admin.',
        };
      }

      if (userRef != null) {
        await userRef.set({
          'lastLogin': fb_fs.FieldValue.serverTimestamp(),
          'lastLoginIP': '192.168.1.1',
        }, fb_fs.SetOptions(merge: true));
      }

      return {
        'success': true,
        'userId': uid,
        'role': role,
        'instituteId': instituteId,
        'instituteName': instituteName,
        'userData': userData,
      };
    } on fb_auth.FirebaseAuthException catch (e) {
      return ErrorHandler.formatErrorForUI(e, context: 'signInWithEmail', appType: 'admin');
    } catch (e) {
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }

  /// Sign in with USER ID and password
  Future<Map<String, dynamic>> signInWithId({
    required String userId,
    required String password,
    required String role,
  }) async {
    try {
      // 1. Find User by ID and Role
      fb_fs.QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .where('role', isEqualTo: role)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {'success': false, 'message': 'User ID not found'};
      }

      fb_fs.DocumentSnapshot userDoc = querySnapshot.docs.first;
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String email = userData['email'];

      // 2. Authenticate using the found email
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. 🔒 SECURITY CHECK: Only allow admin role
      String userRole = userData['role'] ?? '';
      if (userRole != 'admin') {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Access denied. Only Admin can login.'
        };
      }

      // 4. Update Stats
      await _firestore.collection('users').doc(userDoc.id).update({
        'lastLogin': fb_fs.FieldValue.serverTimestamp(),
        'lastLoginIP': '192.168.1.1',
      });

      return {
        'success': true,
        'userId': userDoc.id,
        'role': userData['role'],
        'userData': userData,
      };
    } on fb_auth.FirebaseAuthException catch (e) {
      return ErrorHandler.formatErrorForUI(e, context: 'signInWithEmail', appType: 'admin');
    } catch (e) {
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }

  // ========== 2FA OTP METHODS ==========

  Future<Map<String, dynamic>> sendOTP(String userId) async {
    try {
      String otp = _generateOTP();
      _otpStorage[userId] = otp;
      
      // In production, integrate SMS API here
      if (kDebugMode) debugPrint('🔐 SECURITY OTP for $userId: $otp'); 

      return {
        'success': true,
        'message': 'OTP sent',
        'otp': otp, 
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to send OTP'};
    }
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String userId,
    required String otp,
  }) async {
    String? storedOtp = _otpStorage[userId];
    if (storedOtp == null || storedOtp != otp) {
      return {'success': false, 'message': 'Invalid or expired OTP'};
    }
    _otpStorage.remove(userId);
    return {'success': true, 'message': 'OTP verified'};
  }

  // ========== HELPER METHODS ==========

  String _generateOTP() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) debugPrint('Error signing out: $e');
    }
  }

  // ========== INSTITUTE REGISTRATION METHODS ==========

  /// Send OTP for registration (mobile verification)
  /// Note: Phone number duplicate check is done during registration, not here
  /// This allows unauthenticated users to request OTP
  Future<Map<String, dynamic>> sendRegistrationOTP(String mobile) async {
    try {
      final phoneError = ValidationService.validatePhone(mobile);
      if (phoneError != null) {
        return {'success': false, 'message': phoneError};
      }
      final cleanMobile = mobile.replaceAll(RegExp(r'[\s\-\(\)]'), '');

      // Generate OTP
      String otp = _generateOTP();
      String verificationId = 'VER_${DateTime.now().millisecondsSinceEpoch}_$cleanMobile';
      
      // Store OTP temporarily (in production, use Firebase Phone Auth or SMS service)
      _registrationOtpStorage[verificationId] = otp;
      _verificationIdStorage[cleanMobile] = verificationId;
      
      // In production, integrate SMS API here (e.g., Twilio, Firebase Phone Auth)
      // For now, using demo OTP (shown in console/UI)
      if (kDebugMode) debugPrint('📱 REGISTRATION OTP for $cleanMobile: $otp');
      if (kDebugMode) debugPrint('Verification ID: $verificationId');

      return {
        'success': true,
        'message': 'OTP sent successfully',
        'otp': otp, // Demo only - remove in production
        'verificationId': verificationId,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to send OTP: ${e.toString()}'};
    }
  }

  /// Verify registration OTP
  Future<Map<String, dynamic>> verifyRegistrationOTP({
    required String verificationId,
    required String otp,
    required String mobile,
  }) async {
    String? storedOtp = _registrationOtpStorage[verificationId];
    
    if (storedOtp == null) {
      return {'success': false, 'message': 'Invalid verification ID or OTP expired'};
    }
    
    if (storedOtp != otp) {
      return {'success': false, 'message': 'Invalid OTP'};
    }
    
    // OTP verified - remove from storage
    _registrationOtpStorage.remove(verificationId);
    _verificationIdStorage.remove(mobile);
    
    return {'success': true, 'message': 'OTP verified successfully'};
  }

  /// Register a new user for an institute
  /// Note: Admin IS the user - there's no separate user entity
  Future<Map<String, dynamic>> registerInstituteUser({
    required String instituteId,
    required String instituteName,
    required String name,
    required String email,
    required String password,
    required String mobile,
  }) async {
    try {
      final cleanName = ValidationService.sanitizeInput(name);
      final cleanEmail = ValidationService.sanitizeInput(email).toLowerCase();
      final cleanMobile = mobile.replaceAll(RegExp(r'[\s\-\(\)]'), '');

      final nameError = ValidationService.validateName(cleanName);
      if (nameError != null) return {'success': false, 'message': nameError};
      final emailError = ValidationService.validateEmail(cleanEmail);
      if (emailError != null) return {'success': false, 'message': emailError};
      final phoneError = ValidationService.validatePhone(cleanMobile);
      if (phoneError != null) return {'success': false, 'message': phoneError};
      final passwordError = ValidationService.validatePassword(password, isRegistration: true);
      if (passwordError != null) return {'success': false, 'message': passwordError};

      // Duplicate checks before Firebase Auth creation for clearer messages.
      final emailDup = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      if (emailDup.docs.isNotEmpty) {
        return {'success': false, 'message': 'Email already exists. Please use another email.'};
      }

      final phoneDup = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: cleanMobile)
          .limit(1)
          .get();
      if (phoneDup.docs.isNotEmpty) {
        return {'success': false, 'message': 'Mobile number already exists. Please use another number.'};
      }

      final nameDupExact = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('users')
          .where('name', isEqualTo: cleanName)
          .limit(1)
          .get();
      final nameDupLower = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('users')
          .where('nameLower', isEqualTo: cleanName.toLowerCase())
          .limit(1)
          .get();
      if (nameDupExact.docs.isNotEmpty || nameDupLower.docs.isNotEmpty) {
        return {'success': false, 'message': 'Name already exists in this institute. Please use a different name.'};
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'instituteId': instituteId,
        'instituteName': instituteName,
        'name': cleanName,
        'nameLower': cleanName.toLowerCase(),
        'email': cleanEmail,
        'phoneNumber': cleanMobile,
        'role': 'admin',
        'createdAt': fb_fs.FieldValue.serverTimestamp(),
        'lastLogin': null,
        'status': 'pending',
      }, fb_fs.SetOptions(merge: true));

      // Mirror profile in top-level users collection for robust login fallback.
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'instituteId': instituteId,
        'instituteName': instituteName,
        'name': cleanName,
        'nameLower': cleanName.toLowerCase(),
        'email': cleanEmail,
        'phoneNumber': cleanMobile,
        'role': 'admin',
        'createdAt': fb_fs.FieldValue.serverTimestamp(),
        'lastLogin': null,
        'status': 'pending',
      }, fb_fs.SetOptions(merge: true));

      await _firestore.collection('institutes').doc(instituteId).set({
        'userCount': fb_fs.FieldValue.increment(1),
        'lastUserAdded': fb_fs.FieldValue.serverTimestamp(),
      }, fb_fs.SetOptions(merge: true));

      await _auth.signOut();

      return {
        'success': true,
        'message': 'Registration submitted. Super admin approval is required before login.',
        'userId': userCredential.user!.uid,
      };
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return {'success': false, 'message': 'Email already exists. Please use another email.'};
      }
      return ErrorHandler.formatErrorForUI(e, context: 'registerInstituteUser', appType: 'admin');
    } catch (e) {
      return ErrorHandler.formatErrorForUI(e, context: 'registerInstituteUser', appType: 'admin');
    }
  }

  // ========== INSTITUTE MANAGEMENT METHODS ==========

  /// Initialize default institutes in the database
  /// (Removed: no default institutes are auto-created)

  // ========== UPDATE EXISTING METHODS FOR INSTITUTE SUPPORT ==========

  /// Update signInWithEmail to support institute-based login
  Future<Map<String, dynamic>> signInWithEmailAndInstitute({
    required String email,
    required String password,
    String? instituteId, // Optional: if provided, validate against specific institute
  }) async {
    try {
      // 1. Authenticate with Firebase Auth
      fb_auth.UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Find user in institutes collection
      fb_fs.QuerySnapshot? userQuery;
      try {
        userQuery = await _firestore
            .collectionGroup('users')
            .where('uid', isEqualTo: userCredential.user!.uid)
            .limit(1)
            .get();
      } catch (_) {
        userQuery = null;
      }

      Map<String, dynamic>? userData;
      String? userInstituteId;
      fb_fs.DocumentReference? userRef;

      if (userQuery != null && userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;
        userData = userDoc.data() as Map<String, dynamic>;
        userInstituteId = userData['instituteId'] as String?;
        userRef = userDoc.reference;
      } else {
        final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        if (doc.exists) {
          userData = doc.data();
          userInstituteId = (userData?['instituteId'] ?? '').toString();
          userRef = doc.reference;
        }
      }

      if (userData == null) {
        await _auth.signOut();
        return {'success': false, 'message': 'User not found in Firebase profile.'};
      }

      // 3. If instituteId provided, validate match
      if (instituteId != null && userInstituteId != instituteId) {
        await _auth.signOut();
        return {'success': false, 'message': 'User does not belong to this institute'};
      }

      // 4. Security check: Only allow admin role
      String role = userData['role'] ?? '';
      if (role != 'admin') {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Access denied. Only Admin can login.'
        };
      }

      final status = (userData['status'] ?? 'active').toString().toLowerCase();
      if (status != 'active' && status != 'approved') {
        await _auth.signOut();
        if (status == 'pending') {
          return {
            'success': false,
            'message': 'Your registration is pending super admin approval.',
          };
        }
        return {
          'success': false,
          'message': 'Your account is not active. Contact super admin.',
        };
      }

      // 5. Update last login
      await userRef!.set({
        'lastLogin': fb_fs.FieldValue.serverTimestamp(),
        'lastLoginIP': '192.168.1.1',
      }, fb_fs.SetOptions(merge: true));

      return {
        'success': true,
        'userId': userCredential.user!.uid,
        'role': userData['role'],
        'instituteId': userInstituteId,
        'instituteName': userData['instituteName'],
        'userData': userData,
      };
    } on fb_auth.FirebaseAuthException catch (e) {
      return ErrorHandler.formatErrorForUI(e, context: 'signInWithEmail', appType: 'admin');
    } catch (e) {
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }
}




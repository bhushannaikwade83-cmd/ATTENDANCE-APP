import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:math';
import 'error_handler.dart';
import 'validation_service.dart';
import 'batch_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    String? uid;
    try {
      // Validate inputs
      final emailError = ValidationService.validateEmail(email);
      if (emailError != null) {
        return {'success': false, 'message': emailError};
      }

      final passwordError = ValidationService.validatePassword(password, isRegistration: true);
      if (passwordError != null) {
        return {'success': false, 'message': passwordError};
      }

      final nameError = ValidationService.validateName(name);
      if (nameError != null) {
        return {'success': false, 'message': nameError};
      }

      // Sanitize inputs
      email = ValidationService.sanitizeInput(email);
      name = ValidationService.sanitizeInput(name);

      // Check for dangerous content
      if (ValidationService.containsDangerousContent(email) ||
          ValidationService.containsDangerousContent(name)) {
        return {'success': false, 'message': 'Invalid characters detected in input'};
      }

      // 1. Create Auth User
      if (kDebugMode) debugPrint('🔐 Creating Firebase Auth user for: $email');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      uid = userCredential.user!.uid;
      if (kDebugMode) debugPrint('✅ Firebase Auth user created - UID: $uid');

      // 2. Create Firestore Doc
      if (kDebugMode) debugPrint('📝 Creating Firestore document at users/$uid');
      try {
        // Validate adminId
        final adminIdError = ValidationService.validateRollNumber(adminId);
        if (adminIdError != null) {
          // Clean up auth user
          try {
            await _auth.currentUser?.delete();
          } catch (_) {}
          return {'success': false, 'message': adminIdError};
        }

        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'userId': ValidationService.sanitizeInput(adminId),
          'name': name,
          'email': email,
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': null,
        });
        if (kDebugMode) debugPrint('✅ Firestore document created successfully');
        
        // Verify the document was created
        final verifyDoc = await _firestore.collection('users').doc(uid).get();
        if (!verifyDoc.exists) {
          if (kDebugMode) debugPrint('⚠️ WARNING: Document was not created or cannot be read');
          // Don't sign out yet, keep user authenticated so they can retry
          return {
            'success': false,
            'message': 'Document creation failed. Please try again or contact support.\n\nUID: $uid'
          };
        }
        if (kDebugMode) debugPrint('✅ Document verified - exists: ${verifyDoc.exists}');
      } on FirebaseException catch (firestoreError) {
        if (kDebugMode) debugPrint('❌ Firestore error: ${firestoreError.code} - ${firestoreError.message}');
        // Sign out the auth user since we couldn't create the document
        try {
          await _auth.signOut();
        } catch (_) {}
        return {
          'success': false,
          'message': 'Failed to create user profile: ${firestoreError.message}\n\nError code: ${firestoreError.code}\n\nPlease check Firestore rules allow document creation.'
        };
      } catch (firestoreError) {
        if (kDebugMode) debugPrint('❌ Unexpected Firestore error: $firestoreError');
        // Sign out the auth user since we couldn't create the document
        try {
          await _auth.signOut();
        } catch (_) {}
        return {
          'success': false,
          'message': 'Failed to create user profile: ${firestoreError.toString()}'
        };
      }

      // 3. Force Sign Out
      if (kDebugMode) debugPrint('🔓 Signing out user after successful registration');
      await _auth.signOut();

      return {'success': true, 'message': 'Admin created successfully'};
    } on FirebaseAuthException catch (e) {
      // If auth user was created but Firestore failed, try to delete the auth user
      if (uid != null) {
        try {
          final user = _auth.currentUser;
          if (user != null) {
            await user.delete();
            if (kDebugMode) debugPrint('🗑️ Deleted orphaned auth user');
          }
        } catch (_) {}
      }
      return ErrorHandler.formatErrorForUI(e, context: 'registerAdmin');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Unexpected error: $e');
      // If auth user was created but something else failed, try to delete the auth user
      if (uid != null) {
        try {
          final user = _auth.currentUser;
          if (user != null) {
            await user.delete();
            if (kDebugMode) debugPrint('🗑️ Deleted orphaned auth user');
          }
        } catch (_) {}
      }
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
    String? batchId, // Batch ID from batch management
    String? batchName, // Batch name (for backward compatibility)
    String? batchTiming, // Batch timing (for backward compatibility)
    String? subject, // Selected subject from batch
    String? instituteId, // Optional: if provided, save to institute structure
  }) async {
    // Validate inputs
    final nameError = ValidationService.validateName(name);
    if (nameError != null) {
      return {'success': false, 'message': nameError};
    }

    final rollNumberError = ValidationService.validateRollNumber(rollNumber);
    if (rollNumberError != null) {
      return {'success': false, 'message': rollNumberError};
    }

    // Sanitize inputs
    name = ValidationService.sanitizeInput(name);
    rollNumber = ValidationService.sanitizeInput(rollNumber);
    year = ValidationService.sanitizeInput(year);
    contactNo = ValidationService.sanitizeInput(contactNo);
    if (batchName != null) {
      batchName = ValidationService.sanitizeInput(batchName);
    }
    if (batchTiming != null) {
      batchTiming = ValidationService.sanitizeInput(batchTiming);
    }

    // Check for dangerous content
    if (ValidationService.containsDangerousContent(name) ||
        ValidationService.containsDangerousContent(rollNumber) ||
        ValidationService.containsDangerousContent(year) ||
        ValidationService.containsDangerousContent(contactNo)) {
      return {'success': false, 'message': 'Invalid characters detected in input'};
    }

    try {
      String? currentInstituteId = instituteId;
      
      // If instituteId not provided, try to get it from current user
      if (currentInstituteId == null && _auth.currentUser != null) {
        final uid = _auth.currentUser!.uid;
        
        // Try to find user's institute ID
        try {
          final knownInstituteIds = ['3333', 'dummy01'];
          for (var instId in knownInstituteIds) {
            try {
              final doc = await _firestore
                  .collection('institutes')
                  .doc(instId)
                  .collection('users')
                  .doc(uid)
                  .get();
              
              if (doc.exists) {
                final userData = doc.data();
                // Use the institute document ID (instId) as the primary identifier
                currentInstituteId = instId; // Use the actual document ID
                if (currentInstituteId != null) break;
              }
            } catch (_) {
              continue;
            }
          }
          
          // If not found, try querying all institutes
          if (currentInstituteId == null) {
            final institutesSnapshot = await _firestore
                .collection('institutes')
                .limit(50)
                .get();
            
            for (var instituteDoc in institutesSnapshot.docs) {
              try {
                final doc = await _firestore
                    .collection('institutes')
                    .doc(instituteDoc.id)
                    .collection('users')
                    .doc(uid)
                    .get();
                
                if (doc.exists) {
                  final userData = doc.data();
                  // Use the institute document ID as the primary identifier
                  currentInstituteId = instituteDoc.id; // Use the actual document ID
                  if (currentInstituteId != null) break;
                }
              } catch (_) {
                continue;
              }
            }
          }
        } catch (e) {
          if (kDebugMode) debugPrint('❌ Error getting institute ID: $e');
        }
      }
      
      // If still no institute ID found, log error
      if (currentInstituteId == null || currentInstituteId.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ CRITICAL: Could not determine institute ID for current user');
          debugPrint('   User UID: ${_auth.currentUser?.uid}');
          debugPrint('   This is required for multi-tenant student management');
        }
      }

      // 1. Validate that we have an institute ID - REQUIRED for multi-tenant structure
      if (currentInstituteId == null || currentInstituteId.isEmpty) {
        if (kDebugMode) debugPrint('❌ ERROR: Cannot add student - Institute ID not found for current user');
        return {
          'success': false,
          'message': 'Cannot add student: Institute ID not found. Please ensure you are logged in as an admin of an institute.'
        };
      }

      // 2. Check if Roll Number already exists in the same batch
      try {
        if (batchId != null) {
          // If batchId is provided, check for exact batch match
          final existing = await _firestore
              .collection('institutes')
              .doc(currentInstituteId)
              .collection('students')
              .where('userId', isEqualTo: rollNumber)
              .where('batchId', isEqualTo: batchId)
              .limit(1)
              .get();

          if (existing.docs.isNotEmpty) {
            return {'success': false, 'message': 'Roll Number already exists in this batch'};
          }
        } else if (batchName != null) {
          // Fallback: Use case-insensitive batch name matching for backward compatibility
          final existingStudents = await _firestore
              .collection('institutes')
              .doc(currentInstituteId)
              .collection('students')
              .where('userId', isEqualTo: rollNumber)
              .get();

          final normalizedNewBatch = ValidationService.normalizeBatchName(batchName);
          
          for (var doc in existingStudents.docs) {
            final existingBatchName = doc.data()['batchName'] as String? ?? '';
            final normalizedExistingBatch = ValidationService.normalizeBatchName(existingBatchName);
            
            if (normalizedNewBatch == normalizedExistingBatch) {
              if (kDebugMode) {
                debugPrint('⚠️ Duplicate found: Roll $rollNumber already exists in batch "$existingBatchName"');
              }
              return {
                'success': false, 
                'message': 'Roll Number already exists in this batch. Existing batch: "$existingBatchName"'
              };
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Error checking duplicate in institute: $e');
        // Continue anyway - let Firestore rules handle duplicates if needed
      }

      // 3. Create a specific ID for manual entries (e.g., "MANUAL_123")
      String docId = 'MANUAL_${DateTime.now().millisecondsSinceEpoch}';

      // 4. Save to Firestore in institute structure ONLY (no fallback to old structure)
      try {
        if (kDebugMode) {
          debugPrint('📝 Adding student to institute: $currentInstituteId, Roll: $rollNumber');
          debugPrint('   Path: institutes/$currentInstituteId/students/$docId');
          debugPrint('   User UID: ${_auth.currentUser?.uid}');
          
          // Verify user has permission before saving
          if (_auth.currentUser != null) {
            try {
              final userCheck = await _firestore
                  .collection('institutes')
                  .doc(currentInstituteId)
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .get();
              debugPrint('   User exists in institute: ${userCheck.exists}');
              if (!userCheck.exists) {
                debugPrint('   Checking old structure...');
                final oldUserCheck = await _firestore
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .get();
                if (oldUserCheck.exists) {
                  final oldUserData = oldUserCheck.data();
                  debugPrint('   User found in old structure with role: ${oldUserData?['role']}');
                  debugPrint('   ✅ Rules should allow this (backward compatibility)');
                }
              }
            } catch (checkError) {
              debugPrint('   ⚠️ Could not verify user document: $checkError');
            }
          }
        }
        
        final studentData = {
          'uid': docId, // No Auth UID, so use Doc ID
          'userId': rollNumber,
          'name': name,
          'email': '', // No email (empty string is allowed by rules)
          'phoneNumber': contactNo, // Store contact number
          'year': year, // Store year
          if (batchId != null) 'batchId': batchId, // Batch ID from batch management
          'batchName': batchName ?? '', // Batch name (for backward compatibility)
          'batchTiming': batchTiming ?? '', // Batch timing (for backward compatibility)
          if (subject != null && subject.isNotEmpty) 'subject': subject, // Selected subject from batch
          'role': 'student',
          'status': 'approved', // Auto-approved since Admin added them
          'hasDevice': false, // 🚩 Flag to identify they don't use the app
          'instituteId': currentInstituteId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': null,
        };
        
        if (kDebugMode) {
          debugPrint('   Student data to save:');
          debugPrint('     - name: $name (valid: ${ValidationService.validateName(name) == null})');
          debugPrint('     - userId: $rollNumber (valid: ${ValidationService.validateRollNumber(rollNumber) == null})');
          debugPrint('     - batchId: $batchId');
          debugPrint('     - batchName: $batchName');
          debugPrint('     - email: "" (empty, should be allowed)');
        }
        
        await _firestore
            .collection('institutes')
            .doc(currentInstituteId)
            .collection('students')
            .doc(docId)
            .set(studentData);
        
        // Increment batch student count if batchId is provided
        if (batchId != null) {
          try {
            final batchService = BatchService();
            await batchService.incrementStudentCount(currentInstituteId, batchId);
            if (kDebugMode) debugPrint('✅ Batch student count incremented');
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ Error incrementing batch count: $e');
            // Don't fail the student creation if batch count update fails
          }
        }
        
        // Update institute student count
        try {
          await _firestore.collection('institutes').doc(currentInstituteId).update({
            'studentCount': FieldValue.increment(1),
          });
        } catch (e) {
          // Non-critical error - student is already saved
          if (kDebugMode) debugPrint('⚠️ Warning: Could not update student count: $e');
        }
        
        if (kDebugMode) {
          debugPrint('✅ Student added successfully to institute: $currentInstituteId');
          debugPrint('   Saved at: institutes/$currentInstituteId/students/$docId');
        }
        
        return {
          'success': true, 
          'message': 'Student added successfully to batch',
          'instituteId': currentInstituteId,
          'studentId': docId,
        };
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ ERROR saving student to institute structure: $e');
          debugPrint('   Institute ID: $currentInstituteId');
          debugPrint('   Roll Number: $rollNumber');
        }
        
        // Return error - do NOT fall back to old structure
        return {
          'success': false,
          'message': 'Failed to save student: ${e.toString()}. Please try again or contact support.'
        };
      }
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
      // 1. Authenticate
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;
      DocumentSnapshot? userDoc;
      String? instituteId;
      String? instituteName;
      
      if (kDebugMode) debugPrint('Login attempt - Email: $email, UID: $uid');

      // 2. Try to find user in new institute structure using collectionGroup query
      // First try collectionGroup query (requires index but faster)
      try {
        final instituteUserQuery = await _firestore
            .collectionGroup('users')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();

        if (instituteUserQuery.docs.isNotEmpty) {
          userDoc = instituteUserQuery.docs.first;
          final userData = userDoc.data() as Map<String, dynamic>?;
          if (userData != null) {
            instituteId = userData['instituteId'] as String?;
            instituteName = userData['instituteName'] as String?;
          }
        }
      } catch (e) {
        // If collectionGroup fails (permission or index issue), fallback to checking each institute
        if (kDebugMode) debugPrint('CollectionGroup query failed, trying direct access: $e');
        
        try {
          // Fallback: Check each institute directly
          // Use isActive field (boolean) instead of status field
          final institutesSnapshot = await _firestore
              .collection('institutes')
              .where('isActive', isEqualTo: true)
              .limit(50) // Limit to prevent timeout
              .get();

          if (kDebugMode) debugPrint('Fallback: Checking ${institutesSnapshot.docs.length} active institutes for user $uid');
          
          // Check each institute for the user
          for (var instituteDoc in institutesSnapshot.docs) {
            try {
              if (kDebugMode) debugPrint('Checking institute: ${instituteDoc.id}');
              final doc = await _firestore
                  .collection('institutes')
                  .doc(instituteDoc.id)
                  .collection('users')
                  .doc(uid)
                  .get();
              
              if (kDebugMode) debugPrint('Institute ${instituteDoc.id} - User document exists: ${doc.exists}');
              
              if (doc.exists) {
                userDoc = doc;
                final userData = doc.data();
                if (userData != null) {
                  instituteId = userData['instituteId'] as String?;
                  instituteName = userData['instituteName'] as String?;
                }
                if (kDebugMode) debugPrint('✅ User found in institute ${instituteDoc.id}');
                break;
              }
            } catch (permissionError) {
              // Skip this institute if there's a permission error
              if (kDebugMode) debugPrint('Error checking institute ${instituteDoc.id}: $permissionError');
              continue;
            }
          }
          
          // If still not found, try without the isActive filter (in case some institutes don't have this field)
          if (userDoc == null || !userDoc.exists) {
            if (kDebugMode) debugPrint('User not found in active institutes, trying all institutes...');
            final allInstitutesSnapshot = await _firestore
                .collection('institutes')
                .limit(50)
                .get();
            
            for (var instituteDoc in allInstitutesSnapshot.docs) {
              try {
                final doc = await _firestore
                    .collection('institutes')
                    .doc(instituteDoc.id)
                    .collection('users')
                    .doc(uid)
                    .get();
                
                if (doc.exists) {
                  userDoc = doc;
                  final userData = doc.data();
                  if (userData != null) {
                    instituteId = userData['instituteId'] as String?;
                    instituteName = userData['instituteName'] as String?;
                  }
                  if (kDebugMode) debugPrint('✅ User found in institute ${instituteDoc.id} (without isActive filter)');
                  break;
                }
              } catch (permissionError) {
                if (kDebugMode) debugPrint('Error checking institute ${instituteDoc.id}: $permissionError');
                continue;
              }
            }
          }
        } catch (fallbackError) {
          if (kDebugMode) debugPrint('Fallback institute search failed: $fallbackError');
          // Continue to old structure check
        }
      }

      // 3. Fallback to old structure (backward compatibility)
      if (userDoc == null || !userDoc.exists) {
        if (kDebugMode) debugPrint('User not found in institute structure, checking old users collection...');
        if (kDebugMode) debugPrint('Looking for user with UID: $uid');
        
        try {
          // Try reading the document directly
          userDoc = await _firestore
              .collection('users')
              .doc(uid)
              .get();

          if (kDebugMode) debugPrint('Old users collection check - exists: ${userDoc.exists}');
          if (kDebugMode) debugPrint('Document ID checked: $uid');
          
          if (!userDoc.exists) {
            // Document doesn't exist at UID path - try querying by email
            if (kDebugMode) debugPrint('Document not found at UID path ($uid), trying email query...');
            try {
              final emailQuery = await _firestore
                  .collection('users')
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .get();
              
              if (kDebugMode) debugPrint('Email query result: ${emailQuery.docs.length} documents found');
              
              if (emailQuery.docs.isNotEmpty) {
                userDoc = emailQuery.docs.first;
                final foundData = userDoc.data() as Map<String, dynamic>?;
                if (kDebugMode) debugPrint('User found by email query!');
                if (kDebugMode) debugPrint('Document ID: ${userDoc.id}');
                if (kDebugMode) debugPrint('UID in document: ${foundData?['uid']}');
                if (kDebugMode) debugPrint('Firebase Auth UID: $uid');
                if (kDebugMode) debugPrint('Role: ${foundData?['role']}');
                
                // Check if UID in document matches Firebase Auth UID
                final docUid = foundData?['uid'] as String?;
                if (docUid != uid) {
                  if (kDebugMode) debugPrint('WARNING: Document UID ($docUid) does not match Firebase Auth UID ($uid)');
                  if (kDebugMode) debugPrint('This is a mismatch - document should be at users/$uid, but it\'s at users/${userDoc.id}');
                  
                  // Try to migrate/update the document
                  try {
                    // Move document to correct location (users/{uid})
                    await _firestore.collection('users').doc(uid).set(foundData!);
                    // Optionally delete old document (or keep it for reference)
                    // await _firestore.collection('users').doc(userDoc.id).delete();
                    
                    // Re-read from correct location
                    userDoc = await _firestore.collection('users').doc(uid).get();
                    if (kDebugMode) debugPrint('Document migrated to correct location: users/$uid');
                  } catch (migrateError) {
                    if (kDebugMode) debugPrint('Failed to migrate document: $migrateError');
                    // Continue with found document anyway
                  }
                }
              }
            } catch (queryError) {
              if (kDebugMode) debugPrint('Email query failed: $queryError');
            }
            
            if (userDoc == null || !userDoc.exists) {
              await _auth.signOut();
              return {
                'success': false, 
                'message': 'User profile not found. Please ensure you are registered as an admin user.\n\nTroubleshooting:\n1. Verify your email: $email\n2. Check if document exists in Firestore "users" collection\n3. Ensure document ID is your Firebase Auth UID: $uid\n4. Try creating a new admin account from Setup screen'
              };
            }
          }
          
          final oldUserData = userDoc.data() as Map<String, dynamic>?;
          if (kDebugMode) debugPrint('User found in old structure - role: ${oldUserData?['role']}, email: ${oldUserData?['email']}');
        } catch (e) {
          if (kDebugMode) debugPrint('Error accessing old users collection: $e');
          await _auth.signOut();
          return {
            'success': false, 
            'message': 'Error accessing user profile: ${e.toString()}\n\nPlease check:\n1. Firestore rules allow reading your document\n2. You are authenticated with Firebase Auth\n3. Document exists in collection "users" with ID matching your UID ($uid)'
          };
        }
      }

      // At this point, userDoc is guaranteed to be non-null (either from institute structure or old structure)
      if (!userDoc.exists) {
        await _auth.signOut();
        return {
          'success': false, 
          'message': 'User profile not found. Please register first.'
        };
      }

      Map<String, dynamic>? userDataMap = userDoc.data() as Map<String, dynamic>?;
      if (userDataMap == null) {
        await _auth.signOut();
        return {
          'success': false, 
          'message': 'User profile data is empty. Please register again.'
        };
      }
      
      Map<String, dynamic> userData = userDataMap;

          // 4. 🔒 SECURITY CHECK: Only allow admin role
          // For institute structure: user must be admin in institutes/{instituteId}/users/{uid}
          // For old structure: user must be admin in users/{uid} (backward compatibility)
          String role = userData['role'] ?? '';
          if (role != 'admin') {
            await _auth.signOut();
            return {
              'success': false,
              'message': 'Access denied. Only Institute Admin can login.\n\nYour role: $role\n\nPlease ensure you are registered as an admin for your institute.'
            };
          }
          
          // Additional check: If in institute structure, verify instituteId exists
          if (instituteId != null && instituteId.isNotEmpty) {
            if (kDebugMode) debugPrint('✅ User is admin of institute: $instituteId ($instituteName)');
          } else {
            if (kDebugMode) debugPrint('⚠️ User is admin but instituteId not found (old structure or missing data)');
          }

      // 5. Update Stats (only if user document exists and we have permission)
      try {
        await userDoc.reference.update({
          'lastLogin': FieldValue.serverTimestamp(),
          'lastLoginIP': '192.168.1.1',
        });
      } catch (e) {
        // If update fails, log but don't fail login
        if (kDebugMode) debugPrint('Warning: Could not update lastLogin: $e');
      }

      return {
        'success': true,
        'userId': uid,
        'role': userData['role'],
        'instituteId': instituteId,
        'instituteName': instituteName,
        'userData': userData,
      };
    } on FirebaseAuthException catch (e) {
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
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .where('role', isEqualTo: role)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {'success': false, 'message': 'User ID not found'};
      }

      DocumentSnapshot userDoc = querySnapshot.docs.first;
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
        'lastLogin': FieldValue.serverTimestamp(),
        'lastLoginIP': '192.168.1.1',
      });

      return {
        'success': true,
        'userId': userDoc.id,
        'role': userData['role'],
        'userData': userData,
      };
    } on FirebaseAuthException catch (e) {
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

  /// Handle Firebase Auth errors with user-friendly messages
  /// Logs detailed error info for developers in console
  // Error handling is now done by ErrorHandler service
  // Keeping this for backward compatibility but redirecting to ErrorHandler
  @Deprecated('Use ErrorHandler.handleAuthError instead')
  String _handleAuthError(FirebaseAuthException e) {
    return ErrorHandler.handleAuthError(e);
  }

  String _generateOTP() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ========== INSTITUTE REGISTRATION METHODS ==========

  /// Send OTP for registration (mobile verification)
  /// Note: Phone number duplicate check is done during registration, not here
  /// This allows unauthenticated users to request OTP
  Future<Map<String, dynamic>> sendRegistrationOTP(String mobile) async {
    try {
      // Validate mobile number format
      if (mobile.isEmpty || mobile.length != 10) {
        return {'success': false, 'message': 'Invalid mobile number. Must be 10 digits'};
      }

      // Generate OTP
      String otp = _generateOTP();
      String verificationId = 'VER_${DateTime.now().millisecondsSinceEpoch}_$mobile';
      
      // Store OTP temporarily (in production, use Firebase Phone Auth or SMS service)
      _registrationOtpStorage[verificationId] = otp;
      _verificationIdStorage[mobile] = verificationId;
      
      // In production, integrate SMS API here (e.g., Twilio, Firebase Phone Auth)
      // For now, using demo OTP (shown in console/UI)
      if (kDebugMode) debugPrint('📱 REGISTRATION OTP for $mobile: $otp');
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
      // 1. Check if email already exists in this institute (allow read for duplicate checking)
      try {
        final emailCheck = await _firestore
            .collection('institutes')
            .doc(instituteId)
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (emailCheck.docs.isNotEmpty) {
          return {'success': false, 'message': 'Email already registered in this institute'};
        }
      } catch (e) {
        // If query fails (permission denied), continue - Firebase Auth will catch duplicate emails
        if (kDebugMode) debugPrint('Warning: Could not check email existence: $e');
      }

      // 2. Check if mobile number already exists in this institute
      try {
        final mobileCheck = await _firestore
            .collection('institutes')
            .doc(instituteId)
            .collection('users')
            .where('phoneNumber', isEqualTo: mobile)
            .limit(1)
            .get();

        if (mobileCheck.docs.isNotEmpty) {
          return {'success': false, 'message': 'Mobile number already registered in this institute'};
        }
      } catch (e) {
        // If query fails, continue - duplicate mobile check is not critical
        if (kDebugMode) debugPrint('Warning: Could not check mobile existence: $e');
      }

      // 3. Create Firebase Auth User (this will fail if email already exists globally)
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 4. Create Firestore Doc under institute
      await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'instituteId': instituteId,
        'instituteName': instituteName,
        'name': name,
        'email': email,
        'phoneNumber': mobile,
        'role': 'admin', // First user is admin
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': null,
        'status': 'active',
      });

      // 5. Also update institute document to track user count
      await _firestore.collection('institutes').doc(instituteId).update({
        'userCount': FieldValue.increment(1),
        'lastUserAdded': FieldValue.serverTimestamp(),
      });

      // 6. Store credentials for email sending (simulated)
      // In production, use Firebase Cloud Functions to send email
      await _firestore
          .collection('institutes')
          .doc(instituteId)
          .collection('user_credentials')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'password': password, // ⚠️ In production, NEVER store plain passwords
        'createdAt': FieldValue.serverTimestamp(),
        'emailSent': false, // Flag to track if email was sent
        'emailSentAt': null,
      });

      // 7. Simulate email sending (store in Firestore for Cloud Function to pick up)
      // TODO: Implement actual email sending via Cloud Functions
      if (kDebugMode) debugPrint('📧 EMAIL CREDENTIALS for $email:');
      if (kDebugMode) debugPrint('   Email: $email');
      if (kDebugMode) debugPrint('   Password: $password');
      if (kDebugMode) debugPrint('   Institute: $instituteName');
      if (kDebugMode) debugPrint('   NOTE: In production, send via Cloud Functions');

      // 8. Force Sign Out (user should login after receiving email)
      await _auth.signOut();

      return {
        'success': true,
        'message': 'Registration successful! Login credentials sent to your email.',
        'userId': userCredential.user!.uid,
      };
    } on FirebaseAuthException catch (e) {
      return ErrorHandler.formatErrorForUI(e, context: 'registerInstituteUser', appType: 'admin');
    } catch (e) {
      return ErrorHandler.formatErrorForUI(e, context: 'registerInstituteUser', appType: 'admin');
    }
  }

  // ========== INSTITUTE MANAGEMENT METHODS ==========

  /// Initialize default institutes in the database
  /// This should be called during app setup or by admin
  Future<Map<String, dynamic>> initializeDefaultInstitutes() async {
    try {
      if (kDebugMode) debugPrint('📚 Initializing default institutes...');
      List<String> created = [];
      List<String> skipped = [];

      // Create MSCE Pune Institute
      final msceRef = _firestore.collection('institutes').doc('3333');
      final msceExists = await msceRef.get();

      if (!msceExists.exists) {
        await msceRef.set({
          'instituteId': '3333',
          'instituteCode': '3333',
          'name': 'MSCE Pune',
          'location': 'Pune',
          'address': 'Pune',
          'city': 'Pune',
          'district': 'Pune',
          'taluka': 'Haveli',
          'state': 'Maharashtra',
          'country': 'India',
          'mobileNo': '8329012808',
          'isActive': true,
          'userCount': 0,
          'studentCount': 0,
          'lastUserAdded': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        created.add('MSCE Pune (Code: 3333)');
        if (kDebugMode) debugPrint('✅ Created: MSCE Pune (Code: 3333)');
      } else {
        skipped.add('MSCE Pune (already exists)');
        if (kDebugMode) debugPrint('ℹ️  MSCE Pune already exists');
      }

      // Create Lakshya Institute (sample)
      final lakshyaRef = _firestore.collection('institutes').doc('dummy01');
      final lakshyaExists = await lakshyaRef.get();

      if (!lakshyaExists.exists) {
        await lakshyaRef.set({
          'instituteId': 'dummy01',
          'instituteCode': '',
          'name': 'Lakshya Institute',
          'location': 'Dombivali West',
          'address': 'Dombivali West',
          'city': 'Mumbai',
          'district': '',
          'taluka': '',
          'state': 'Maharashtra',
          'country': 'India',
          'mobileNo': '',
          'isActive': true,
          'userCount': 0,
          'studentCount': 0,
          'lastUserAdded': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        created.add('Lakshya Institute (ID: dummy01)');
        if (kDebugMode) debugPrint('✅ Created: Lakshya Institute (ID: dummy01)');
      } else {
        skipped.add('Lakshya Institute (already exists)');
        if (kDebugMode) debugPrint('ℹ️  Lakshya Institute already exists');
      }

      if (kDebugMode) debugPrint('✨ Institute initialization completed!');
      return {
        'success': true,
        'message': 'Institutes initialized successfully',
        'created': created,
        'skipped': skipped,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error initializing institutes: $e');
      return {
        'success': false,
        'message': 'Error initializing institutes: ${e.toString()}',
      };
    }
  }

  /// Create a new institute
  Future<Map<String, dynamic>> createInstitute({
    required String instituteId,
    required String name,
    String? instituteCode,
    String? location,
    String? address,
    String? city,
    String? district,
    String? taluka,
    String? state,
    String? country,
    String? mobileNo,
  }) async {
    try {
      // Check if institute already exists (by ID or code)
      final existingById = await _firestore
          .collection('institutes')
          .doc(instituteId)
          .get();

      if (existingById.exists) {
        return {'success': false, 'message': 'Institute with this ID already exists'};
      }

      // Check if institute code already exists (if provided)
      if (instituteCode != null && instituteCode.isNotEmpty) {
        final existingByCode = await _firestore
            .collection('institutes')
            .where('instituteCode', isEqualTo: instituteCode)
            .get();

        if (existingByCode.docs.isNotEmpty) {
          return {'success': false, 'message': 'Institute with this code already exists'};
        }
      }

      // Create institute document
      await _firestore.collection('institutes').doc(instituteId).set({
        'instituteId': instituteId,
        'instituteCode': instituteCode ?? '',
        'name': name,
        'location': location ?? '',
        'address': address ?? '',
        'city': city ?? '',
        'district': district ?? '',
        'taluka': taluka ?? '',
        'state': state ?? '',
        'country': country ?? 'India',
        'mobileNo': mobileNo ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'userCount': 0,
        'studentCount': 0,
        'lastUserAdded': null,
      });

      return {
        'success': true,
        'message': 'Institute created successfully',
        'instituteId': instituteId,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error creating institute: ${e.toString()}'};
    }
  }

  // ========== UPDATE EXISTING METHODS FOR INSTITUTE SUPPORT ==========

  /// Update signInWithEmail to support institute-based login
  Future<Map<String, dynamic>> signInWithEmailAndInstitute({
    required String email,
    required String password,
    String? instituteId, // Optional: if provided, validate against specific institute
  }) async {
    try {
      // 1. Authenticate with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Find user in institutes collection
      final userQuery = await _firestore
          .collectionGroup('users')
          .where('uid', isEqualTo: userCredential.user!.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        await _auth.signOut();
        return {'success': false, 'message': 'User not found in any institute'};
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      final userInstituteId = userData['instituteId'] as String?;

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

      // 5. Update last login
      await userDoc.reference.update({
        'lastLogin': FieldValue.serverTimestamp(),
        'lastLoginIP': '192.168.1.1',
      });

      return {
        'success': true,
        'userId': userCredential.user!.uid,
        'role': userData['role'],
        'instituteId': userInstituteId,
        'instituteName': userData['instituteName'],
        'userData': userData,
      };
    } on FirebaseAuthException catch (e) {
      return ErrorHandler.formatErrorForUI(e, context: 'signInWithEmail', appType: 'admin');
    } catch (e) {
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }
}

// Script to create a coder account for error dashboard access
// Run this from Firebase Console or use Firebase Admin SDK

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  // Coder credentials
  final coderEmail = 'coder001@gmail.com'; // Coder email
  final coderPassword = 'Bhushan@70'; // Coder password
  final coderName = 'Coder 001'; // Coder name

  try {
    // 1. Create Firebase Auth user
    print('Creating Firebase Auth user...');
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: coderEmail,
      password: coderPassword,
    );

    final uid = userCredential.user!.uid;
    print('✅ Auth user created: $uid');

    // 2. Create coder document
    print('Creating coder document...');
    await firestore.collection('coders').doc(uid).set({
      'uid': uid,
      'email': coderEmail,
      'name': coderName,
      'role': 'coder',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': null,
    });

    print('✅ Coder account created successfully!');
    print('Email: $coderEmail');
    print('Password: $coderPassword');
    print('UID: $uid');
    print('\nYou can now login to coder dashboard with these credentials.');

    // Sign out
    await auth.signOut();
  } catch (e) {
    print('❌ Error creating coder account: $e');
  }
}

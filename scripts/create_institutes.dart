import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  print('🚀 Initializing Firebase...');
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
    return;
  }

  final firestore = FirebaseFirestore.instance;

  print('\n📝 Creating institutes...\n');

  // Create MSCE Pune Institute
  final msceData = {
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
  };

  try {
    // Check if already exists
    final existing = await firestore.collection('institutes').doc('3333').get();
    
    if (existing.exists) {
      print('⚠️  MSCE Pune (Code: 3333) already exists in database');
    } else {
      await firestore.collection('institutes').doc('3333').set(msceData);
      print('✅ Created: MSCE Pune (Code: 3333)');
      print('   📍 Address: Pune, District: Pune, Taluka: Haveli');
      print('   📞 Mobile: 8329012808');
    }
  } catch (e) {
    print('❌ Error creating MSCE Pune: $e');
  }

  // Create Lakshya Institute (if doesn't exist)
  final lakshyaData = {
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
  };

  try {
    final existing = await firestore.collection('institutes').doc('dummy01').get();
    
    if (existing.exists) {
      print('⚠️  Lakshya Institute (ID: dummy01) already exists in database');
    } else {
      await firestore.collection('institutes').doc('dummy01').set(lakshyaData);
      print('✅ Created: Lakshya Institute (ID: dummy01)');
      print('   📍 Location: Dombivali West, Mumbai');
    }
  } catch (e) {
    print('❌ Error creating Lakshya Institute: $e');
  }

  print('\n✨ Institute creation process completed!\n');
  print('📊 Verifying institutes in database...\n');

  try {
    final allInstitutes = await firestore.collection('institutes').get();
    print('📚 Total institutes in database: ${allInstitutes.docs.length}');
    for (var doc in allInstitutes.docs) {
      final data = doc.data();
      print('   - ${data['name']} (Code: ${data['instituteCode'] ?? 'N/A'}, ID: ${doc.id})');
    }
  } catch (e) {
    print('❌ Error reading institutes: $e');
  }

  print('\n🎉 Done!');
}

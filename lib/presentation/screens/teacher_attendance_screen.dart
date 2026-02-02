import 'dart:typed_data'; 
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  static const routeName = '/teacher-attendance';
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final String _todayDateId = DateTime.now().toString().split(' ')[0];
  Map<String, dynamic> _attendanceMap = {};
  bool _isLoading = true;
  final Map<String, bool> _uploadingStates = {};

  late FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    // Initialize Face Detector (Mobile Only)
    if (!kIsWeb) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableClassification: false,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
    }
    _fetchTodayAttendance();
  }

  @override
  void dispose() {
    if (!kIsWeb) _faceDetector.close();
    super.dispose();
  }

  void _fetchTodayAttendance() {
    FirebaseFirestore.instance
        .collection('attendance')
        .where('date', isEqualTo: _todayDateId)
        .snapshots()
        .listen((snapshot) {
      final tempMap = <String, dynamic>{};
      for (var doc in snapshot.docs) {
        tempMap[doc['studentId']] = doc.data();
      }
      if (mounted) {
        setState(() {
          _attendanceMap = tempMap;
          _isLoading = false;
        });
      }
    });
  }

  // 🌍 STRICT GPS CHECK (With Anti-Cheat)
  Future<bool> _isWithinSchoolPremises() async {
    if (kIsWeb) return true; // Web Bypass for testing

    try {
      final doc = await FirebaseFirestore.instance.collection('system_settings').doc('gps_config').get();
      if (!doc.exists) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Warning: GPS Config missing.")));
        return true; 
      }
      final data = doc.data()!;
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if(mounted) _showErrorDialog("Permission Denied", "Location permission is required.");
          return false;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      // 🛡️ 1. ANTI-CHEAT: Check for Fake GPS
      if (position.isMocked) {
        if(mounted) _showErrorDialog("Fake GPS Detected", "Please turn off Mock Location apps.");
        return false;
      }

      double dist = Geolocator.distanceBetween(
        position.latitude, position.longitude, 
        data['latitude'], data['longitude']
      );

      // 🛡️ 2. GEOFENCE CHECK
      double maxAllowed = data['radius'] + 20.0; // 20m buffer
      if (dist > maxAllowed) {
        if (mounted) _showErrorDialog("Outside School", "You are ${dist.toStringAsFixed(0)}m away.\nAllowed radius: ${data['radius']}m.");
        return false;
      }
      return true;
    } catch (e) {
      if(mounted) _showErrorDialog("GPS Error", e.toString());
      return false; 
    }
  }

  // 📸 CAPTURE & UPLOAD FLOW
  Future<void> _captureAndMarkPresent(String studentId, String studentName) async {
    
    // 🛑 STEP 1: Strict GPS Check
    bool isAllowed = await _isWithinSchoolPremises();
    if (!isAllowed) return;

    final picker = ImagePicker();
    
    // 🛑 STEP 2: Open Camera
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 35,
      maxWidth: 600,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (photo == null) return;

    setState(() => _uploadingStates[studentId] = true);

    try {
      // 🛑 STEP 3: Face Detection (Mobile Only)
      if (!kIsWeb) {
        final inputImage = InputImage.fromFilePath(photo.path);
        final List<Face> faces = await _faceDetector.processImage(inputImage);
        
        if (faces.isEmpty) {
          if (mounted) _showErrorDialog("No Face Detected", "No person found.\nPlease retake the photo.");
          setState(() => _uploadingStates[studentId] = false);
          return;
        }
      }

      // 🛑 STEP 4: Upload (Bytes Method)
      String filePath = 'attendance_proofs/$_todayDateId/${studentId}_manual.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(filePath);
      
      Uint8List imgBytes = await photo.readAsBytes();
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      
      await ref.putData(imgBytes, metadata); 

      // Retry URL fetch
      String downloadUrl = "";
      int attempts = 0;
      while (attempts < 3) {
        try {
          downloadUrl = await ref.getDownloadURL();
          break; 
        } catch (e) {
          attempts++;
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }

      if (downloadUrl.isEmpty) throw "Upload successful but URL retrieval failed.";

      // 🛑 STEP 5: Save to Firestore
      final docId = '${studentId}_$_todayDateId';
      await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
        'studentId': studentId,
        'studentName': studentName,
        'date': _todayDateId,
        'status': 'present',
        'timestamp': FieldValue.serverTimestamp(),
        'markedBy': 'Teacher',
        'isManual': true,
        'verificationSelfie': downloadUrl,
        'locationVerified': true,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verified & Saved!"), backgroundColor: Colors.green));
      }

    } catch (e) {
      if (mounted) _showErrorDialog("Error", "Could not verify: $e");
    } finally {
      if (mounted) setState(() => _uploadingStates[studentId] = false);
    }
  }

  Future<void> _markAbsent(String studentId, String studentName) async {
    final docId = '${studentId}_$_todayDateId';
    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'studentId': studentId,
      'studentName': studentName,
      'date': _todayDateId,
      'status': 'absent',
      'timestamp': FieldValue.serverTimestamp(),
      'markedBy': 'Teacher',
      'isManual': true,
      'verificationSelfie': null,
    }, SetOptions(merge: true));
  }

  void _viewProofImage(String url, String name, String time) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue,
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text("$name's Proof", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                  const CloseButton(color: Colors.white),
                ],
              ),
            ),
            Container(
              height: 400,
              color: Colors.black,
              child: Image.network(
                url, 
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (context, error, stackTrace) => const Center(child: Text("Image Error", style: TextStyle(color: Colors.white))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Marked at: $time", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String content) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: Text(content), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance: ${DateFormat('MMM d').format(DateTime.now())}"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('status', isEqualTo: 'approved')
            .limit(100) // Limit to avoid internal assertion errors
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || _isLoading) return const Center(child: CircularProgressIndicator());
          final students = snapshot.data!.docs;
          if (students.isEmpty) return const Center(child: Text("No students found."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index].data() as Map<String, dynamic>;
              final studentId = students[index].id;
              final name = student['name'] ?? 'Unknown';
              final hasDevice = student['hasDevice'] ?? true;
              
              final record = _attendanceMap[studentId];
              final status = record != null ? record['status'] : null;
              final selfieUrl = record != null ? record['verificationSelfie'] : null;
              final isUploading = _uploadingStates[studentId] ?? false;
              
              String time = "Unknown";
              if (record != null && record['timestamp'] != null) {
                time = DateFormat('h:mm a').format((record['timestamp'] as Timestamp).toDate());
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: hasDevice ? Colors.blue.shade100 : Colors.orange.shade100,
                        child: Icon(hasDevice ? Icons.phone_android : Icons.person_off, color: hasDevice ? Colors.blue : Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            if (isUploading) 
                              const Text("Uploading...", style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic))
                            else if (status == 'present')
                              Text("Present • $time", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold))
                            else if (status == 'absent')
                              Text("Absent", style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold))
                            else
                              const Text("Not Marked", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      
                      // 1. APP STUDENTS (With Phone)
                      if (hasDevice) 
                        if (status == 'present' && selfieUrl != null)
                          IconButton(
                            icon: const Icon(Icons.image_search, color: Colors.blue),
                            tooltip: "View Student's Selfie",
                            onPressed: () => _viewProofImage(selfieUrl, name, time),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                            child: const Text("App User", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          )
                      
                      // 2. MANUAL STUDENTS (No Phone)
                      else 
                        _buildManualActions(studentId, name, status, selfieUrl, isUploading, time),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildManualActions(String id, String name, String? status, String? selfieUrl, bool isUploading, String time) {
    if (isUploading) return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));

    if (status == 'present' && selfieUrl != null) {
      return InkWell(
        onTap: () => _viewProofImage(selfieUrl, name, time),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(8)
          ),
          child: const Row(children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            SizedBox(width: 4),
            Text("Proof", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
          ]),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _markAbsent(id, name)),
        ElevatedButton.icon(
          onPressed: () => _captureAndMarkPresent(id, name),
          icon: const Icon(Icons.camera_alt, size: 16),
          label: const Text("Proof"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        ),
      ],
    );
  }
}

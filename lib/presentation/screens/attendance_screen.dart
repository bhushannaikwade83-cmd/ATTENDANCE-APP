import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  static const routeName = '/student-attendance';
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  final String _todayDateId = DateTime.now().toString().split(' ')[0];

  bool _isLoading = false;
  bool _isMarked = false;

  String? _proofUrl;
  String? _markTime;
  String? _instituteId;

  late FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
        ),
      );
    }

    _loadInstituteId();
  }

  @override
  void dispose() {
    if (!kIsWeb) _faceDetector.close();
    super.dispose();
  }

  /* ================== LOAD INSTITUTE ================== */

  Future<void> _loadInstituteId() async {
    if (user == null) return;

    setState(() => _isLoading = true);

    final institutes =
        await FirebaseFirestore.instance.collection('institutes').get();

    for (final inst in institutes.docs) {
      final adminDoc = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(inst.id)
          .collection('users')
          .doc(user!.uid)
          .get();

      if (adminDoc.exists) {
        _instituteId = inst.id;
        break;
      }
    }

    if (_instituteId == null) {
      _showError("Access Denied", "Institute not linked with this account.");
      setState(() => _isLoading = false);
      return;
    }

    await _checkStatus();
  }

  /* ================== CHECK STATUS ================== */

  Future<void> _checkStatus() async {
    if (user == null || _instituteId == null) return;

    final docId = '${user!.uid}_$_todayDateId';

    final doc = await FirebaseFirestore.instance
        .collection('institutes')
        .doc(_instituteId)
        .collection('attendance')
        .doc(docId)
        .get();

    if (doc.exists) {
      final ts = doc['timestamp'] as Timestamp;

      setState(() {
        _isMarked = true;
        _proofUrl = doc['verificationSelfie'];
        _markTime = DateFormat('h:mm a').format(ts.toDate());
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  /* ================== LOCATION CHECK ================== */

  Future<bool> _checkLocation() async {
    try {
      final configDoc = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(_instituteId)
          .collection('gps_settings')
          .doc('config')
          .get();

      if (!configDoc.exists) return true;

      final data = configDoc.data()!;

      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied) return false;
      }

      final pos = await Geolocator.getCurrentPosition();

      if (pos.isMocked) return false;

      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        data['latitude'],
        data['longitude'],
      );

      return distance <= data['radius'] + 20;
    } catch (_) {
      return false;
    }
  }

  /* ================== MARK ATTENDANCE ================== */

  Future<void> _markAttendance() async {
    if (user == null || _instituteId == null) return;

    setState(() => _isLoading = true);

    if (!kIsWeb) {
      final ok = await _checkLocation();
      if (!ok) {
        _showError("Location Error", "You are outside allowed area.");
        setState(() => _isLoading = false);
        return;
      }
    }

    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 40,
      preferredCameraDevice: CameraDevice.front,
    );

    if (photo == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (!kIsWeb) {
        final faces = await _faceDetector
            .processImage(InputImage.fromFilePath(photo.path));
        if (faces.isEmpty) {
          _showError("Face Error", "No face detected.");
          setState(() => _isLoading = false);
          return;
        }
      }

      final bytes = await photo.readAsBytes();

      final ref = FirebaseStorage.instance
          .ref()
          .child('attendance_photos')
          .child(_instituteId!)
          .child('${user!.uid}_$_todayDateId.jpg');

      await ref.putData(bytes);
      final photoUrl = await ref.getDownloadURL();

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final name = userDoc.data()?['name'] ?? 'Student';

      final docId = '${user!.uid}_$_todayDateId';

      await FirebaseFirestore.instance
          .collection('institutes')
          .doc(_instituteId)
          .collection('attendance')
          .doc(docId)
          .set({
        'studentId': user!.uid,
        'studentName': name,
        'date': _todayDateId,
        'status': 'present',
        'timestamp': FieldValue.serverTimestamp(),
        'verificationSelfie': photoUrl,
        'markedBy': 'Student',
        'isManual': false,
        'locationVerified': true,
      });

      await _checkStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance Marked Successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError("Error", e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  /* ================== UI ================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mark Attendance")),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _isMarked
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 90, color: Colors.green),
                      const SizedBox(height: 20),
                      Text("Present",
                          style: Theme.of(context).textTheme.headlineMedium),
                      Text("Marked at $_markTime"),
                      const SizedBox(height: 20),
                      if (_proofUrl != null)
                        Image.network(_proofUrl!, height: 200),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: _markAttendance,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Mark Attendance"),
                  ),
      ),
    );
  }
}

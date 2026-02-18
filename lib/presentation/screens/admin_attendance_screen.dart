import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/batch_service.dart';
import '../../services/backblaze_b2_secure_service.dart';
import '../../services/storage_path_service.dart';
import '../../services/image_compression_service.dart';

class AdminAttendanceScreen extends StatefulWidget {
  static const routeName = '/admin-attendance';
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final BatchService _batchService = BatchService();
  final picker = ImagePicker();

  User? _user;
  String? instituteId;
  String instituteName = 'unknown_institute';

  bool isLoading = false;
  bool isLocationValid = false;
  bool isLoadingBatches = false;

  List<Map<String, dynamic>> batches = [];
  List<String> students = [];

  Map<String, dynamic>? selectedBatch;
  String? _selectedBatchId;
  String? selectedSubject;
  String? selectedRollNumber;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _user = FirebaseAuth.instance.currentUser;
    await _loadInstitute();
    await _loadBatches();
    await _checkLocation();
  }

  Future<void> _loadInstitute() async {
    if (_user == null) return;
    final insts = await FirebaseFirestore.instance.collection('institutes').limit(100).get();
    for (final inst in insts.docs) {
      final u = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(inst.id)
          .collection('users')
          .doc(_user!.uid)
          .get();
      if (u.exists) {
        instituteId = inst.id;
        instituteName = (inst.data()['name'] ?? inst.id).toString();
        break;
      }
    }
    setState(() {});
  }

  Future<void> _loadBatches() async {
    if (instituteId == null) return;
    setState(() => isLoadingBatches = true);
    batches = await _batchService.getBatches(instituteId!);
    // If the currently selected batch id no longer exists (or duplicates exist),
    // reset selection to avoid DropdownButton value mismatch.
    final ids = batches.map((b) => (b['id'] ?? '').toString().trim()).where((v) => v.isNotEmpty).toSet();
    if (_selectedBatchId != null && !ids.contains(_selectedBatchId)) {
      _selectedBatchId = null;
      selectedBatch = null;
      selectedSubject = null;
      selectedRollNumber = null;
    }
    setState(() => isLoadingBatches = false);
  }

  Future<void> _loadStudentsForBatch() async {
    if (instituteId == null || selectedBatch == null) return;
    setState(() => isLoading = true);
    final snapshot = await FirebaseFirestore.instance
        .collection('institutes')
        .doc(instituteId)
        .collection('students')
        .where('batchId', isEqualTo: selectedBatch!['id'])
        .get();
    students = snapshot.docs
        .map((d) => (d.data()['userId'] ?? '').toString())
        .where((v) => v.isNotEmpty)
        .toList()
      ..sort();
    setState(() => isLoading = false);
  }

  Future<void> _checkLocation() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        isLocationValid = false;
      } else {
        isLocationValid = await _isWithinAdminGeofence();
      }
    } catch (_) {
      isLocationValid = false;
    }
    setState(() {});
  }

  Future<bool> _isWithinAdminGeofence() async {
    if (_user == null || instituteId == null) return false;
    try {
      final gpsCollection = FirebaseFirestore.instance
          .collection('institutes')
          .doc(instituteId)
          .collection('gps_settings');

      var configDoc = await gpsCollection.doc(_user!.uid).get();
      if (!configDoc.exists) {
        configDoc = await gpsCollection.doc('config').get();
      }
      if (!configDoc.exists) {
        return true;
      }

      final data = configDoc.data() ?? <String, dynamic>{};
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      final radius = ((data['radius'] as num?)?.toDouble() ?? 100.0) + 20.0;
      if (lat == null || lng == null) return true;

      final pos = await Geolocator.getCurrentPosition();
      if (pos.isMocked) return false;

      final distance = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
      return distance <= radius;
    } catch (_) {
      return false;
    }
  }

  bool get canMark =>
      !isLoading &&
      isLocationValid &&
      instituteId != null &&
      selectedBatch != null &&
      selectedSubject != null &&
      selectedRollNumber != null;

  Future<void> _markAttendance() async {
    if (!canMark) return;
    setState(() => isLoading = true);

    try {
      final withinGeoFence = await _isWithinAdminGeofence();
      if (!withinGeoFence) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are outside your configured class GPS radius.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 40);
      if (photo == null) {
        setState(() => isLoading = false);
        return;
      }

      final bytes = await photo.readAsBytes();
      final compressedBytes = await ImageCompressionService.compressToTarget(
        input: bytes,
        targetBytes: ImageCompressionService.targetBytes50kb,
      );

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final subject = selectedSubject!;
      final roll = selectedRollNumber!;
      final batchName = (selectedBatch?['name'] ?? 'general_batch').toString();

      final storagePath = StoragePathService.buildAttendancePhotoPath(
        instituteName: instituteName,
        batchName: batchName,
        subject: subject,
        studentName: 'roll_$roll',
        date: today,
        lectureKey: subject,
      );

      final selfiePath = await BackblazeB2SecureService.uploadFile(
        objectPath: storagePath,
        bytes: compressedBytes,
      );

      final docId = '${roll}_${subject.replaceAll(' ', '_')}_$today';
      await FirebaseFirestore.instance
          .collection('institutes')
          .doc(instituteId)
          .collection('attendance')
          .doc(docId)
          .set({
        'rollNumber': roll,
        'subject': subject,
        'date': today,
        'verificationSelfie': selfiePath,
        'photoPath': storagePath,
        'photoSizeBytes': compressedBytes.lengthInBytes,
        'timestamp': FieldValue.serverTimestamp(),
        'markedBy': _user?.uid ?? 'unknown',
        'batchId': selectedBatch?['id'],
        'batchName': batchName,
        'instituteId': instituteId,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance marked'), backgroundColor: Colors.green),
      );

      setState(() {
        selectedSubject = null;
        selectedRollNumber = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Deduplicate / normalize batch ids so DropdownButton doesn't crash when:
    // - value isn't present in items (stale selection after reload)
    // - items contain duplicate ids (Firestore/data issues)
    final batchOptions = <String, Map<String, dynamic>>{};
    for (final b in batches) {
      final id = (b['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      batchOptions.putIfAbsent(id, () => b);
    }
    final selectedBatchValue =
        (_selectedBatchId != null && batchOptions.containsKey(_selectedBatchId)) ? _selectedBatchId : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + bottomInset * 0.3, // extra space for small screens / keyboard
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isLocationValid)
                      const Text('Location not verified', style: TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    if (isLoadingBatches)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<String>(
                        value: selectedBatchValue,
                        decoration: const InputDecoration(labelText: 'Batch'),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black87),
                        iconEnabledColor: Colors.black54,
                        items: batchOptions.entries
                            .map((e) {
                              final b = e.value;
                              return DropdownMenuItem<String>(
                                value: e.key,
                                child: Text(
                                  '${b['name']} (${b['year']})',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              );
                            })
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedBatchId = value;
                            selectedBatch = batchOptions[value];
                            selectedSubject = null;
                            selectedRollNumber = null;
                          });
                          _loadStudentsForBatch();
                        },
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black87),
                      iconEnabledColor: Colors.black54,
                      items: (selectedBatch?['subjects'] as List<dynamic>? ?? const [])
                          .map((s) => DropdownMenuItem<String>(
                                value: s.toString(),
                                child: Text(s.toString(), style: const TextStyle(color: Colors.black87)),
                              ))
                          .toList(),
                      onChanged: selectedBatch == null ? null : (v) => setState(() => selectedSubject = v),
                    ),
                    const SizedBox(height: 12),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<String>(
                        value: selectedRollNumber,
                        decoration: const InputDecoration(labelText: 'Roll Number'),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black87),
                        iconEnabledColor: Colors.black54,
                        items: students
                            .map((roll) => DropdownMenuItem<String>(
                                  value: roll,
                                  child: Text(roll, style: const TextStyle(color: Colors.black87)),
                                ))
                            .toList(),
                        onChanged: selectedBatch == null ? null : (v) => setState(() => selectedRollNumber = v),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: canMark ? _markAttendance : null,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text(
                          'Take Photo & Mark Attendance',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

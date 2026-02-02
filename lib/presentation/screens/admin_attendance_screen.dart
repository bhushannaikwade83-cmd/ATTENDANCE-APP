import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../services/batch_service.dart';
import '../../core/theme/app_theme.dart';

class AdminAttendanceScreen extends StatefulWidget {
  static const routeName = '/admin-attendance';
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  final picker = ImagePicker();
  final BatchService _batchService = BatchService();

  String? instituteId;
  Map<String, dynamic>? selectedBatch;
  String? selectedSubject;
  String? selectedTiming;
  String? selectedRollNumber;

  bool isLoading = false;
  bool isLocationValid = false;

  List<Map<String, dynamic>> batches = [];
  List<String> students = [];
  bool isLoadingBatches = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
    _init();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadInstitute();
    await _loadBatches();
    await _checkLocation();
  }

  Future<void> _loadBatches() async {
    if (instituteId == null) return;

    setState(() => isLoadingBatches = true);
    try {
      final loadedBatches = await _batchService.getBatches(instituteId!);
      setState(() {
        batches = loadedBatches;
        isLoadingBatches = false;
      });
    } catch (e) {
      setState(() => isLoadingBatches = false);
      if (kDebugMode) debugPrint('Error loading batches: $e');
    }
  }

  Future<void> _loadStudentsForBatch() async {
    if (selectedBatch == null || instituteId == null) return;

    setState(() => isLoading = true);
    try {
      final batchId = selectedBatch!['id'];
      final snapshot = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(instituteId)
          .collection('students')
          .where('batchId', isEqualTo: batchId)
          .get();

      setState(() {
        students = snapshot.docs
            .map((doc) => doc.data()['userId'] as String? ?? '')
            .where((roll) => roll.isNotEmpty)
            .toList()
          ..sort();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (kDebugMode) debugPrint('Error loading students: $e');
    }
  }

  /* ---------------- INSTITUTE ---------------- */

  Future<void> _loadInstitute() async {
    if (user == null) return;

    final institutes =
        await FirebaseFirestore.instance.collection('institutes').get();

    for (final inst in institutes.docs) {
      final u = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(inst.id)
          .collection('users')
          .doc(user!.uid)
          .get();

      if (u.exists) {
        instituteId = inst.id;
        debugPrint('✅ Institute: $instituteId');
        return;
      }
    }
  }

  /* ---------------- LOCATION ---------------- */

  Future<void> _checkLocation() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) {
        isLocationValid = false;
      } else {
        await Geolocator.getCurrentPosition();
        isLocationValid = true;
      }
    } catch (_) {
      isLocationValid = false;
    }
    setState(() {});
  }

  bool canMark() {
    return !isLoading &&
        isLocationValid &&
        instituteId != null &&
        selectedBatch != null &&
        selectedSubject != null &&
        selectedRollNumber != null;
  }

  /* ---------------- MARK ATTENDANCE ---------------- */

  Future<void> _markAttendance() async {
    setState(() => isLoading = true);

    try {
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 40,
      );

      if (photo == null) {
        setState(() => isLoading = false);
        return;
      }

      final Uint8List bytes = await photo.readAsBytes();

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final subjectKey = selectedSubject!.replaceAll(' ', '_');
      final docId = '${selectedRollNumber}_${subjectKey}_$today';

      // Organize by batch folder: institutes/{instituteId}/batches/{batchId}/attendance/{date}/{docId}.jpg
      final batchId = selectedBatch?['id'] ?? 'unknown';
      final batchName = selectedBatch?['name']?.toString().replaceAll(' ', '_') ?? 'unknown';
      final storagePath =
          'institutes/$instituteId/batches/$batchId/attendance/$today/$docId.jpg';

      final ref = FirebaseStorage.instance.ref(storagePath);
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      debugPrint(
          '🔥 FINAL WRITE PATH: institutes/$instituteId/attendance/$docId');

      await FirebaseFirestore.instance
          .collection('institutes')
          .doc(instituteId)
          .collection('attendance')
          .doc(docId)
          .set({
        'rollNumber': selectedRollNumber,
        'subject': selectedSubject,
        'date': today,
        'photoUrl': url,
        'timestamp': FieldValue.serverTimestamp(),
        'markedBy': user!.uid,
        'batchId': selectedBatch?['id'],
        'batchName': selectedBatch?['name'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Attendance marked'),
          backgroundColor: Colors.green,
        ),
      );

      selectedBatch = null;
      selectedSubject = null;
      selectedTiming = null;
      selectedRollNumber = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlueDark,
              AppTheme.primaryBlueLight,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildModernAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),

            // Step 1: Select Batch - Large Card
            _buildStepCard(
              stepNumber: 1,
              title: 'Select Batch',
              icon: Icons.groups_outlined,
              iconColor: AppTheme.primaryBlue,
              child: isLoadingBatches
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : batches.isEmpty
                      ? _buildGlassInfoCard(
                          icon: Icons.info_outline,
                          iconColor: AppTheme.accentOrange,
                          title: 'No batches created yet',
                          message: 'Please create a batch first from Batch Management',
                        )
                      : _buildModernDropdown(
                          value: selectedBatch?['id'],
                          label: 'Select Batch *',
                          icon: Icons.groups_outlined,
                          items: batches.map((batch) {
                            final displayName = '${batch['name']} (${batch['year']})';
                            return DropdownMenuItem<String>(
                              value: batch['id'] as String,
                              child: Text(displayName, style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                          onChanged: (batchId) {
                            if (batchId != null) {
                              setState(() {
                                selectedBatch = batches.firstWhere((b) => b['id'] == batchId);
                                selectedSubject = null;
                                selectedTiming = selectedBatch!['timing'];
                                selectedRollNumber = null;
                              });
                              _loadStudentsForBatch();
                            }
                          },
                        ),
            ),
            const SizedBox(height: 16),

            // Step 2: Select Subject (only if batch is selected)
            if (selectedBatch != null) ...[
              _buildStepCard(
                stepNumber: 2,
                title: 'Select Subject',
                icon: Icons.book_outlined,
                iconColor: AppTheme.primaryGreen,
                child: _buildModernDropdown(
                  value: selectedSubject,
                  label: 'Select Subject *',
                  icon: Icons.book_outlined,
                  items: (selectedBatch!['subjects'] as List<dynamic>?)
                          ?.map((subject) => DropdownMenuItem(
                                value: subject.toString(),
                                child: Text(subject.toString(), style: const TextStyle(color: Colors.white)),
                              ))
                          .toList() ??
                      [],
                  onChanged: (subject) {
                    setState(() {
                      selectedSubject = subject;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Step 3: Display Timing - Info Card
              _buildStepCard(
                stepNumber: 3,
                title: 'Batch Timing',
                icon: Icons.access_time_outlined,
                iconColor: AppTheme.accentOrange,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedTiming ?? selectedBatch!['timing'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Class timing',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Step 4: Select Roll Number
              _buildStepCard(
                stepNumber: 4,
                title: 'Select Roll Number',
                icon: Icons.badge_outlined,
                iconColor: AppTheme.accentYellow,
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _buildModernDropdown(
                        value: selectedRollNumber,
                        label: 'Select Roll Number *',
                        icon: Icons.badge_outlined,
                        items: students
                            .map((roll) => DropdownMenuItem(
                                  value: roll,
                                  child: Text('Roll $roll', style: const TextStyle(color: Colors.white)),
                                ))
                            .toList(),
                        onChanged: (roll) {
                          setState(() {
                            selectedRollNumber = roll;
                          });
                        },
                      ),
              ),
              const SizedBox(height: 32),

                        // Mark Attendance Button - Large and Prominent
                        Container(
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF3F4F6)]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt, size: 28, color: AppTheme.primaryBlue),
                            label: const Text(
                              'Take Photo & Mark Attendance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: canMark() ? _markAttendance : null,
                          ),
                        ),
            ],

                        const SizedBox(height: 20),
                        if (!isLocationValid)
                          _buildGlassInfoCard(
                            icon: Icons.location_off,
                            iconColor: AppTheme.accentRed,
                            title: 'Location Not Verified',
                            message: 'Please enable location services to mark attendance',
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Mark Attendance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mark Student Attendance',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Follow the steps below to mark attendance',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$stepNumber',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        dropdownColor: AppTheme.primaryBlueDark,
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

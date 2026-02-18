import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/batch_service.dart';
import '../../services/error_handler.dart';
import '../../services/face_recognition_service.dart';

class AddStudentScreen extends StatefulWidget {
  static const routeName = '/add-student';
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen>
    with TickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _yearController = TextEditingController();
  final _contactController = TextEditingController();

  final AuthService _authService = AuthService();
  final BatchService _batchService = BatchService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isCapturingFace = false;
  bool _isLoadingBatches = false;

  String? _facePhotoPath;
  String? _instituteId;

  List<String> _selectedSubjects = [];
  List<Map<String, dynamic>> _batches = [];
  Map<String, dynamic>? _selectedBatch;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _loadInstituteId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _yearController.dispose();
    _contactController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadInstituteId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;

      final topDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final topInstituteId =
          (topDoc.data()?['instituteId'] ?? '').toString().trim();

      if (topInstituteId.isNotEmpty) {
        setState(() => _instituteId = topInstituteId);
        await _loadBatches();
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Institute load error: $e");
    }
  }

  Future<void> _loadBatches() async {
    if (_instituteId == null) return;

    setState(() => _isLoadingBatches = true);

    try {
      _batches = await _batchService.getBatches(_instituteId!);
    } catch (e) {
      if (kDebugMode) debugPrint("Batch load error: $e");
    }

    setState(() => _isLoadingBatches = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBatch == null || _selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select batch and subject(s)"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.addStudentManually(
      name: _nameController.text.trim(),
      rollNumber: _rollController.text.trim(),
      year: _yearController.text.trim(),
      contactNo: _contactController.text.trim(),
      batchId: _selectedBatch!['id'],
      batchName: _selectedBatch!['name'],
      batchTiming: _selectedBatch!['timing'],
      subject: _selectedSubjects.first,
      subjects: _selectedSubjects,
    );

    if (result['success'] &&
        _facePhotoPath != null &&
        result['instituteId'] != null &&
        result['studentId'] != null) {
      try {
        await FaceRecognitionService.saveFaceTemplate(
          _facePhotoPath!,
          result['instituteId'],
          _rollController.text.trim(),
          result['studentId'],
        );
      } catch (_) {}
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success']
              ? "Student Added Successfully"
              : result['message'],
        ),
      ),
    );

    if (result['success']) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue,
                AppTheme.primaryBlueDark,
                AppTheme.primaryBlueLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(_nameController, "Full Name"),
                    const SizedBox(height: 16),
                    _buildTextField(_rollController, "Roll Number"),
                    const SizedBox(height: 16),
                    _buildTextField(_yearController, "Year"),
                    const SizedBox(height: 16),
                    _buildTextField(_contactController, "Contact Number"),
                    const SizedBox(height: 24),

                    // Batch + Subject selectors
                    if (_isLoadingBatches)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    else if (_batches.isNotEmpty) ...[
                      _buildBatchDropdown(),
                      const SizedBox(height: 16),
                      _buildSubjectSelector(),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No batches found. Please create a batch first.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Add Student"),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
    );
  }

  /// Dropdown to select a batch
  Widget _buildBatchDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBatch?['id'] as String?,
      dropdownColor: AppTheme.primaryBlueDark,
      decoration: InputDecoration(
        labelText: 'Select Batch',
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      iconEnabledColor: Colors.white,
      items: _batches
          .map(
            (b) => DropdownMenuItem<String>(
              value: (b['id'] ?? '').toString(),
              child: Text(
                (b['name'] ?? '').toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          try {
            _selectedBatch = _batches.firstWhere(
              (b) => (b['id'] ?? '').toString() == value,
            );
            _selectedSubjects = [];
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error selecting batch: $e');
            }
            _selectedBatch = null;
            _selectedSubjects = [];
          }
        });
      },
    );
  }

  /// Chip selector to choose one or more subjects from the selected batch
  Widget _buildSubjectSelector() {
    if (_selectedBatch == null) {
      return const SizedBox.shrink();
    }

    final rawSubjects = _selectedBatch!['subjects'];
    List<String> subjects = [];

    if (rawSubjects is List) {
      subjects = rawSubjects
          .map((s) => s.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (rawSubjects is String && rawSubjects.isNotEmpty) {
      subjects = [rawSubjects];
    }

    if (subjects.isEmpty) {
      return Text(
        'No subjects found for this batch.',
        style: TextStyle(color: Colors.white.withOpacity(0.85)),
        textAlign: TextAlign.center,
      );
    }

    final allSelected = _selectedSubjects.length == subjects.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Subjects',
              style: TextStyle(color: Colors.white.withOpacity(0.9)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedSubjects =
                      allSelected ? [] : List<String>.from(subjects);
                });
              },
              child: Text(
                allSelected ? 'Clear All' : 'Select All',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subjects.map((subject) {
            final selected = _selectedSubjects.contains(subject);
            return FilterChip(
              label: Text(
                subject,
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.primaryBlue,
                ),
              ),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedSubjects.add(subject);
                  } else {
                    _selectedSubjects.remove(subject);
                  }
                });
              },
              selectedColor: AppTheme.primaryBlue,
              backgroundColor: Colors.white.withOpacity(0.1),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: selected
                    ? AppTheme.primaryBlue
                    : Colors.white.withOpacity(0.35),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

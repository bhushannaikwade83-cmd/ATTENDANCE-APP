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

class _AddStudentScreenState extends State<AddStudentScreen> with TickerProviderStateMixin {
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
  String? _selectedSubject;
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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
      final knownInstituteIds = ['3333', 'dummy01'];

      for (final instId in knownInstituteIds) {
        final doc = await FirebaseFirestore.instance
            .collection('institutes')
            .doc(instId)
            .collection('users')
            .doc(uid)
            .get();

        if (doc.exists) {
          setState(() => _instituteId = instId);
          await _loadBatches();
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Institute load error: $e');
    }
  }

  Future<void> _loadBatches() async {
    if (_instituteId == null) return;

    setState(() => _isLoadingBatches = true);
    try {
      _batches = await _batchService.getBatches(_instituteId!);
    } catch (e) {
      if (kDebugMode) debugPrint('Batch load error: $e');
    }
    setState(() => _isLoadingBatches = false);
  }

  Future<void> _captureFacePhoto() async {
    setState(() => _isCapturingFace = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (photo != null) {
        setState(() => _facePhotoPath = photo.path);
      }
    } catch (e) {
      final error = ErrorHandler.formatErrorForUI(e, context: 'captureFacePhoto');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['message']),
            backgroundColor: AppTheme.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
    setState(() => _isCapturingFace = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBatch == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select batch and subject'),
          backgroundColor: AppTheme.accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
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
      subject: _selectedSubject,
    );

    if (result['success'] && _facePhotoPath != null) {
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
        content: Text(result['success'] ? 'Student Added Successfully' : result['message']),
        backgroundColor: result['success'] ? AppTheme.accentGreen : AppTheme.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    if (result['success']) Navigator.pop(context, true);
  }

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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildGlassCard(
                            child: Column(
                              children: [
                                _buildModernTextField(
                                  controller: _nameController,
                                  icon: Icons.person_outline,
                                  label: 'Full Name',
                                  hint: 'Enter student name',
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 20),
                                _buildModernTextField(
                                  controller: _rollController,
                                  icon: Icons.badge_outlined,
                                  label: 'Roll Number',
                                  hint: 'Enter roll number',
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 20),
                                _buildModernTextField(
                                  controller: _yearController,
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Year',
                                  hint: 'e.g., First Year',
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 20),
                                if (_isLoadingBatches)
                                  const Center(child: CircularProgressIndicator(color: Colors.white)),
                                if (!_isLoadingBatches && _batches.isNotEmpty) ...[
                                  _buildModernDropdown(
                                    value: _selectedBatch?['id'],
                                    label: 'Select Batch',
                                    icon: Icons.groups_outlined,
                                    items: _batches
                                        .map((b) => DropdownMenuItem<String>(
                                              value: b['id'] as String?,
                                              child: Text(
                                                b['name']?.toString() ?? '',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        _selectedBatch = _batches.firstWhere((b) => b['id'] == v);
                                        _selectedSubject = null;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildModernDropdown(
                                    value: _selectedSubject,
                                    label: 'Select Subject',
                                    icon: Icons.book_outlined,
                                    items: (_selectedBatch?['subjects'] ?? [])
                                        .map<DropdownMenuItem<String>>(
                                          (s) => DropdownMenuItem(
                                            value: s.toString(),
                                            child: Text(
                                              s.toString(),
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) => setState(() => _selectedSubject = v),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                _buildModernTextField(
                                  controller: _contactController,
                                  icon: Icons.phone_outlined,
                                  label: 'Contact Number',
                                  hint: 'Enter contact number',
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 24),
                                _buildFaceCaptureButton(),
                                const SizedBox(height: 24),
                                _buildSubmitButton(),
                              ],
                            ),
                          ),
                        ],
                      ),
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
            child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Add New Student',
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
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.person_add, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Register New Student',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fill in the details below',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.accentRed),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFFE5E5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildModernDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dropdownColor: AppTheme.primaryBlueDark,
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildFaceCaptureButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _facePhotoPath != null ? Icons.check_circle : Icons.camera_alt,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _facePhotoPath == null ? 'Capture Face Photo' : 'Face Photo Captured',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          if (_facePhotoPath == null)
            TextButton(
              onPressed: _isCapturingFace ? null : _captureFacePhoto,
              child: _isCapturingFace
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Capture', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF3F4F6)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: AppTheme.primaryBlue, strokeWidth: 3),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add, color: AppTheme.primaryBlue, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'Add Student',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
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
          child: child,
        ),
      ),
    );
  }
}

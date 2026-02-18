import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backblaze_b2_secure_service.dart';
import 'add_student_screen.dart';

class StudentManagementScreen extends StatefulWidget {
  static const routeName = '/student-management';
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen>
    with TickerProviderStateMixin {
  String? _instituteId;
  bool _isLoadingInstitute = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _loadInstituteId();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadInstituteId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoadingInstitute = false);
        return;
      }

      final uid = user.uid;
      // 1) Try top-level users profile
      final topDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final topInstituteId = (topDoc.data()?['instituteId'] ?? '').toString().trim();
      if (topInstituteId.isNotEmpty) {
        setState(() {
          _instituteId = topInstituteId;
          _isLoadingInstitute = false;
        });
        return;
      }

      // 2) Try collectionGroup users (institute users subcollection)
      try {
        final query = await FirebaseFirestore.instance
            .collectionGroup('users')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          final instId = (data['instituteId'] ?? '').toString().trim();
          if (instId.isNotEmpty) {
            setState(() {
              _instituteId = instId;
              _isLoadingInstitute = false;
            });
            return;
          }
        }
      } catch (_) {}

      setState(() => _isLoadingInstitute = false);
    } catch (e) {
      if (kDebugMode) debugPrint('Institute load error: $e');
      setState(() => _isLoadingInstitute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInstitute) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStudentScreen()),
          );
          if (result == true) {
            await _loadInstituteId();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Student', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryBlue,
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
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Student Management',
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

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: _instituteId != null
          ? FirebaseFirestore.instance
              .collection('institutes')
              .doc(_instituteId)
              .collection('students')
              .snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error loading students',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: _glassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school,
                      size: 60, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(height: 16),
                  const Text(
                    'No students found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }

        final students = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final data = students[index].data() as Map<String, dynamic>;
            final name = (data['name'] ?? 'Unknown').toString();
            final roll = (data['userId'] ?? '').toString();
            final batch = (data['batchName'] ?? '').toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _glassCard(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Roll: $roll | $batch',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentAttendanceDetailsScreen(
                          instituteId: _instituteId!,
                          studentName: name,
                          rollNumber: roll,
                          studentDocId: students[index].id,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _glassCard({required Widget child}) {
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
          child: child,
        ),
      ),
    );
  }
}

class StudentAttendanceDetailsScreen extends StatelessWidget {
  final String instituteId;
  final String studentName;
  final String rollNumber;
  final String studentDocId;

  const StudentAttendanceDetailsScreen({
    super.key,
    required this.instituteId,
    required this.studentName,
    required this.rollNumber,
    required this.studentDocId,
  });

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadAttendance() async {
    final byRoll = await FirebaseFirestore.instance
        .collection('institutes')
        .doc(instituteId)
        .collection('attendance')
        .where('rollNumber', isEqualTo: rollNumber)
        .get();

    final byStudentId = await FirebaseFirestore.instance
        .collection('institutes')
        .doc(instituteId)
        .collection('attendance')
        .where('studentId', isEqualTo: studentDocId)
        .get();

    final map = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final d in byRoll.docs) {
      map[d.id] = d;
    }
    for (final d in byStudentId.docs) {
      map[d.id] = d;
    }

    final docs = map.values.toList();
    docs.sort((a, b) {
      final ta = a.data()['timestamp'];
      final tb = b.data()['timestamp'];
      final da = ta is Timestamp ? ta.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
      final db = tb is Timestamp ? tb.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(studentName),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _loadAttendance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading attendance records'));
          }

          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No daily attendance found for this student'));
          }

          final grouped = <String, List<Map<String, dynamic>>>{};
          for (final doc in docs) {
            final data = doc.data();
            final subject = (data['subject'] ?? 'general_subject').toString();
            grouped.putIfAbsent(subject, () => []);
            grouped[subject]!.add({...data, '_docId': doc.id});
          }

          final subjects = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final entries = grouped[subject]!;
              entries.sort((a, b) {
                final ta = a['timestamp'];
                final tb = b['timestamp'];
                final da = ta is Timestamp ? ta.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                final db = tb is Timestamp ? tb.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                return db.compareTo(da);
              });

              return Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.folder_open),
                  title: Text(subject, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${entries.length} daily records'),
                  children: entries.map((entry) {
                    final ts = entry['timestamp'];
                    final dateField = (entry['date'] ?? '').toString();
                    final dt = ts is Timestamp
                        ? ts.toDate()
                        : (DateTime.tryParse(dateField) ?? DateTime.now());

                    final dateText = DateFormat('dd MMM yyyy').format(dt);
                    final timeText = DateFormat('hh:mm a').format(dt);
                    final photoPath =
                        (entry['verificationSelfie'] ?? entry['photoPath'] ?? '').toString();

                    return _DailyAttendancePhotoTile(
                      dateText: dateText,
                      timeText: timeText,
                      photoPath: photoPath,
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DailyAttendancePhotoTile extends StatelessWidget {
  final String dateText;
  final String timeText;
  final String photoPath;

  const _DailyAttendancePhotoTile({
    required this.dateText,
    required this.timeText,
    required this.photoPath,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(dateText),
      subtitle: Text(timeText),
      trailing: photoPath.isEmpty
          ? const SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.image_not_supported_outlined),
            )
          : FutureBuilder<String>(
              future: BackblazeB2SecureService.getTemporaryDownloadUrl(
                objectPath: photoPath,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(Icons.broken_image_outlined),
                  );
                }

                final url = snapshot.data!;
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(
                          child: Image.network(url, fit: BoxFit.contain),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

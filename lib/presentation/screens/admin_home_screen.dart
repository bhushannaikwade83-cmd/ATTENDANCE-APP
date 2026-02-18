import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/offline_service.dart';
import '../../services/error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../screens/pin_login_screen.dart';
import 'admin_attendance_screen.dart';
import 'student_management_screen.dart';
import 'add_student_screen.dart';
import 'gps_settings_screen.dart';
import 'attendance_reports_screen.dart';
import 'batch_management_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  static const routeName = '/admin-home';
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with TickerProviderStateMixin {
  String? _instituteId;
  bool _isLoadingInstitute = true;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  String get _todayDateId => DateTime.now().toString().split(' ')[0];

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
      final institutesSnapshot = await FirebaseFirestore.instance
          .collection('institutes')
          .limit(100)
          .get();
      
      for (var instituteDoc in institutesSnapshot.docs) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('institutes')
              .doc(instituteDoc.id)
              .collection('users')
              .doc(uid)
              .get();
          
          if (doc.exists) {
            final userData = doc.data();
            setState(() {
              _instituteId = userData?['instituteId'] as String? ?? instituteDoc.id;
              _isLoadingInstitute = false;
            });
            return;
          }
        } catch (_) {
          continue;
        }
      }
      
      setState(() => _isLoadingInstitute = false);
    } catch (e) {
      setState(() => _isLoadingInstitute = false);
      if (kDebugMode) {
        final errorResult = ErrorHandler.formatErrorForUI(e, context: 'loadInstituteId', appType: 'admin');
        debugPrint('Error loading institute: ${errorResult['error']}');
      }
    }
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
                // Modern AppBar
                _buildModernAppBar(),
                // Content
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth > 600 ? 40 : 20,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        _buildWelcomeHeader(),
                        const SizedBox(height: 24),
                        _buildQuickStats(),
                        const SizedBox(height: 24),
                        _buildTodayAttendanceCard(),
                        const SizedBox(height: 24),
                        _buildMarkAttendanceButton(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Management'),
                        const SizedBox(height: 16),
                        _buildManagementCard(
                          title: 'Batch Management',
                          icon: Icons.groups_outlined,
                          color: AppTheme.primaryBlue,
                          items: [
                            _buildMenuItem(
                              icon: Icons.add_circle_outline,
                              title: 'Create Batch',
                              subtitle: 'Create new batch with subjects',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BatchManagementScreen()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildManagementCard(
                          title: 'Student Management',
                          icon: Icons.school_outlined,
                          color: AppTheme.primaryGreen,
                          items: [
                            _buildMenuItem(
                              icon: Icons.person_add_outlined,
                              title: 'Add New Student',
                              subtitle: 'Register new student',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddStudentScreen()),
                              ),
                            ),
                            _buildMenuItem(
                              icon: Icons.people_outlined,
                              title: 'View All Students',
                              subtitle: 'Browse by year',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const StudentManagementScreen()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildManagementCard(
                          title: 'System Settings',
                          icon: Icons.settings_outlined,
                          color: AppTheme.accentOrange,
                          items: [
                            _buildMenuItem(
                              icon: Icons.location_on_outlined,
                              title: 'Geo-fencing Settings',
                              subtitle: 'Configure location & radius',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const GpsSettingsScreen()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildManagementCard(
                          title: 'Reports & Analytics',
                          icon: Icons.analytics_outlined,
                          color: AppTheme.accentGreen,
                          items: [
                            _buildMenuItem(
                              icon: Icons.bar_chart_outlined,
                              title: 'View Attendance Reports',
                              subtitle: 'Analytics & insights',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AttendanceReportsScreen()),
                              ),
                            ),
                          ],
                        ),
                            SizedBox(height: constraints.maxHeight * 0.02 < 24 ? 16 : 24),
                          ],
                        ),
                      );
                    },
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Attendance Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FutureBuilder<int>(
            future: OfflineService.getPendingCount(),
            builder: (context, snapshot) {
              final pendingCount = snapshot.data ?? 0;
              if (pendingCount > 0) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cloud_off, color: Colors.white),
                      onPressed: () async {
                        if (_instituteId != null) {
                          await OfflineService.syncPendingAttendance(_instituteId!);
                          setState(() {});
                        }
                      },
                      tooltip: '$pendingCount pending sync',
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.accentRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, PinLoginScreen.routeName),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
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
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome, Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage attendance & students',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
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

  Widget _buildQuickStats() {
    if (_isLoadingInstitute) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_instituteId == null || _instituteId!.isEmpty) {
      return Row(
        children: [
          Expanded(child: _buildGlassStatCard('Students', '0', Icons.school_outlined, AppTheme.primaryGreen)),
          const SizedBox(width: 12),
          Expanded(child: _buildGlassStatCard('Admins', '0', Icons.admin_panel_settings_outlined, AppTheme.accentGreen)),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('institutes').doc(_instituteId).snapshots(),
      builder: (context, instituteSnap) {
        if (!instituteSnap.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final data = instituteSnap.data?.data() ?? <String, dynamic>{};
        final studentCount = (data['studentCount'] ?? 0).toString();
        final adminCount = (data['userCount'] ?? 0).toString();

        return Row(
          children: [
            Expanded(child: _buildGlassStatCard('Students', studentCount, Icons.school_outlined, AppTheme.primaryGreen)),
            const SizedBox(width: 12),
            Expanded(child: _buildGlassStatCard('Admins', adminCount, Icons.admin_panel_settings_outlined, AppTheme.accentGreen)),
          ],
        );
      },
    );
  }

  Widget _buildGlassStatCard(String title, String value, IconData icon, Color color) {
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayAttendanceCard() {
    if (_isLoadingInstitute) {
      return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _instituteId != null && _instituteId!.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('institutes')
              .doc(_instituteId)
              .collection('attendance')
              .where('date', isEqualTo: _todayDateId)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('attendance')
              .where('date', isEqualTo: _todayDateId)
              .snapshots(),
      builder: (context, snapshot) {
        int present = 0;
        int absent = 0;
        int totalMarked = 0;
        double attendancePercentage = 0.0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalMarked = docs.length;
          present = docs.where((d) {
            final data = d.data() as Map<String, dynamic>? ?? {};
            final status = (data['status'] ?? 'present').toString().toLowerCase();
            return status == 'present';
          }).length;
          absent = docs.where((d) {
            final data = d.data() as Map<String, dynamic>? ?? {};
            final status = (data['status'] ?? 'present').toString().toLowerCase();
            return status == 'absent';
          }).length;
          if (totalMarked > 0) {
            attendancePercentage = (present / totalMarked * 100);
          }
        }

        return _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Today's Attendance",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (totalMarked > 0) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rate',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                    ),
                    Text(
                      '${attendancePercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: attendancePercentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  Expanded(child: _buildAttendanceStat('Present', present, Icons.check_circle_outline)),
                  Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.3)),
                  Expanded(child: _buildAttendanceStat('Absent', absent, Icons.cancel_outlined)),
                  Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.3)),
                  Expanded(child: _buildAttendanceStat('Total', totalMarked, Icons.people_outline)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceStat(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMarkAttendanceButton() {
    return Container(
      height: 80,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            // Reduce padding to avoid RenderFlex overflow on small screens.
            // Height is fixed (80), so large padding leaves too little room for 2 lines of text.
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Mark Attendance',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Take photos of students',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryBlue, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildManagementCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> items,
  }) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.7), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
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

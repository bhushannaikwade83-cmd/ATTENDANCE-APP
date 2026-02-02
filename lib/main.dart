import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // REQUIRED: Ensure this file exists

// Import your screens...
import 'services/session_manager.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/setup_screen.dart';
import 'presentation/screens/admin_home_screen.dart';
import 'presentation/screens/admin_attendance_screen.dart';
import 'presentation/screens/add_student_screen.dart';
import 'presentation/screens/student_management_screen.dart';
import 'presentation/screens/gps_settings_screen.dart';
import 'presentation/screens/attendance_reports_screen.dart';
import 'presentation/screens/institute_search_screen.dart';
import 'presentation/screens/coder_login_screen.dart';
import 'presentation/screens/coder_dashboard_screen.dart';

// 1. Change main to 'async'
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize Firebase HERE. Do not wait for later.
  // This prevents the "JavaScriptObject" crash on startup.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize session manager for security
  SessionManager.initialize();

  // Institutes are created by super admin only - no auto-initialization needed
  // await _initializeInstitutesCollection(); // Removed - only super admin can create institutes

  runApp(const SmartAttendanceApp());
}

/// Initialize institutes collection - REMOVED
/// Institutes must be created by super admin only (via Firestore rules)
/// This function is no longer needed as only authenticated main admin can create institutes
// Future<void> _initializeInstitutesCollection() async {
//   // Removed - institutes are created by super admin only
// }

class SmartAttendanceApp extends StatelessWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduSetu By Digitrix Media',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        SetupScreen.routeName: (_) => const SetupScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        InstituteSearchScreen.routeName: (_) => const InstituteSearchScreen(),
        AdminHomeScreen.routeName: (_) => const AdminHomeScreen(),
        AdminAttendanceScreen.routeName: (_) => const AdminAttendanceScreen(),
        AddStudentScreen.routeName: (_) => const AddStudentScreen(),
        StudentManagementScreen.routeName: (_) => const StudentManagementScreen(),
        GpsSettingsScreen.routeName: (_) => const GpsSettingsScreen(),
        AttendanceReportsScreen.routeName: (_) => const AttendanceReportsScreen(),
        CoderLoginScreen.routeName: (_) => const CoderLoginScreen(),
        CoderDashboardScreen.routeName: (_) => const CoderDashboardScreen(),
      },
    );
  }
}

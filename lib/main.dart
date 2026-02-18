import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
import 'presentation/screens/pin_login_screen.dart';
import 'presentation/screens/pin_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SessionManager.initialize();

  runApp(const SmartAttendanceApp());
}

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
        PinLoginScreen.routeName: (_) => const PinLoginScreen(),
        PinSetupScreen.routeName: (_) => const PinSetupScreen(),
      },
    );
  }
}

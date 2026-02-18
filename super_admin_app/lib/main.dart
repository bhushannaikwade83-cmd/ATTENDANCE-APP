import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/super_admin_dashboard_screen.dart';
import 'screens/super_admin_login_screen.dart';
import 'screens/super_admin_pin_login_screen.dart';
import 'screens/super_admin_pin_setup_screen.dart';
import 'services/super_admin_pin_auth_service.dart';
import 'services/super_admin_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SuperAdminApp());
}

class SuperAdminApp extends StatelessWidget {
  const SuperAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Admin App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F4C81),
          primary: const Color(0xFF0F4C81),
          secondary: const Color(0xFF1B998B),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F7FD),
        cardTheme: const CardThemeData(
          elevation: 4,
          margin: EdgeInsets.zero,
          shadowColor: Color(0x1A0F4C81),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blueGrey.shade100),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blueGrey.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF0F4C81), width: 1.5),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF114B7A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Color(0xCCFFFFFF),
          indicatorColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF1F2937)),
          bodyMedium: TextStyle(color: Color(0xFF374151)),
          titleLarge: TextStyle(color: Color(0xFF111827)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1B998B),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const SuperAdminLoginScreen();
        }

        return FutureBuilder<({bool allowed, String reason})>(
          future: SuperAdminService.checkAccess(user.uid),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (roleSnap.data?.allowed == true) {
              return FutureBuilder<bool>(
                future: SuperAdminPinAuthService.hasPinForUser(user.uid),
                builder: (context, pinSnap) {
                  if (pinSnap.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }

                  final hasPin = pinSnap.data ?? false;
                  if (!hasPin) {
                    // If the user is allowed (super admin) but doesn't have a PIN yet,
                    // route them to PIN setup. The previous "setup allowed in session"
                    // guard could race the authStateChanges rebuild and immediately sign
                    // the user out, making login look like it "does nothing".
                    return SuperAdminPinSetupScreen(onPinSet: _refresh);
                  }

                  if (!SuperAdminPinAuthService.isSessionUnlocked()) {
                    return SuperAdminPinLoginScreen(onPinVerified: _refresh);
                  }

                  return const SuperAdminDashboardScreen();
                },
              );
            }

            final reason = roleSnap.data?.reason ?? 'Super admin access denied';
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0F4C81), Color(0xFF2F6DB1)],
                  ),
                ),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            reason,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              await SuperAdminPinAuthService.lockSession();
                              await FirebaseAuth.instance.signOut();
                            },
                            child: const Text('Back to Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

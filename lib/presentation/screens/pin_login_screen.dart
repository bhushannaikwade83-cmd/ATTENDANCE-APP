import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/pin_auth_service.dart';
import 'admin_home_screen.dart';
import 'login_screen.dart';

class PinLoginScreen extends StatefulWidget {
  static const routeName = '/pin-login';
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final _pinController = TextEditingController();
  bool _checking = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      _show('Enter valid 4-digit PIN');
      return;
    }

    setState(() => _checking = true);
    try {
      final ok = await PinAuthService.verifyPinForCurrentUser(pin);
      if (!mounted) return;
      if (!ok) {
        _show('Incorrect PIN');
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _forgetPin() async {
    await PinAuthService.clearPinForCurrentUser();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PIN reset started. Login with email/password + OTP to set new PIN.'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.accentRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('PIN Login')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Welcome ${user?.email ?? ''}'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: 'Enter 4-digit PIN',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _verifyPin(),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _checking ? null : _verifyPin,
                      child: _checking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Login with PIN'),
                    ),
                    TextButton(
                      onPressed: _checking ? null : _forgetPin,
                      child: const Text('Forget PIN?'),
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

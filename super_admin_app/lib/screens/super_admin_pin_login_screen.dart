import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/super_admin_pin_auth_service.dart';
import 'super_admin_dashboard_screen.dart';
import 'super_admin_pin_reset_screen.dart';

class SuperAdminPinLoginScreen extends StatefulWidget {
  final VoidCallback? onPinVerified;

  const SuperAdminPinLoginScreen({super.key, this.onPinVerified});

  @override
  State<SuperAdminPinLoginScreen> createState() => _SuperAdminPinLoginScreenState();
}

class _SuperAdminPinLoginScreenState extends State<SuperAdminPinLoginScreen> {
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
      final ok = await SuperAdminPinAuthService.verifyPinForCurrentUser(pin);
      if (!mounted) return;
      if (!ok) {
        _show('Incorrect PIN');
        return;
      }
      if (widget.onPinVerified != null) {
        widget.onPinVerified!();
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuperAdminDashboardScreen()),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _forgetPin() async {
    await SuperAdminPinAuthService.clearPinAndLock();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SuperAdminPinResetScreen()),
    );
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B3954), Color(0xFF1F6FA6), Color(0xFF6CA6D9)],
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 52, color: Color(0xFF114B7A)),
                      const SizedBox(height: 10),
                      Text(
                        'Super Admin PIN Login',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(userEmail),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Enter 4-digit PIN',
                          counterText: '',
                        ),
                        onSubmitted: (_) => _verifyPin(),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _checking ? null : _verifyPin,
                          icon: _checking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.login),
                          label: Text(_checking ? 'Checking...' : 'Login with PIN'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _checking ? null : _forgetPin,
                        child: const Text('Forgot PIN? Reset with OTP'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

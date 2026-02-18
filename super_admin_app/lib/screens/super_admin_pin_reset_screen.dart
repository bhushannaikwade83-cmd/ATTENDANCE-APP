import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/super_admin_pin_auth_service.dart';
import '../services/super_admin_service.dart';
import 'super_admin_dashboard_screen.dart';

class SuperAdminPinResetScreen extends StatefulWidget {
  const SuperAdminPinResetScreen({super.key});

  @override
  State<SuperAdminPinResetScreen> createState() => _SuperAdminPinResetScreenState();
}

class _SuperAdminPinResetScreenState extends State<SuperAdminPinResetScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _otpSent = false;
  String? _error;
  String? _debugOtp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _continueWithEmailPassword() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final access = await SuperAdminService.checkAccess(cred.user!.uid);
      if (!access.allowed) {
        await FirebaseAuth.instance.signOut();
        throw Exception(access.reason);
      }

      final otp = await SuperAdminPinAuthService.sendPinResetOtp();
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _debugOtp = otp;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPin() async {
    final otp = _otpController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _error = 'Enter valid 6-digit OTP');
      return;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(newPin)) {
      setState(() => _error = 'PIN must be exactly 4 digits');
      return;
    }
    if (newPin != confirm) {
      setState(() => _error = 'PIN and confirm PIN must match');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SuperAdminPinAuthService.resetPinWithOtp(otp: otp, newPin: newPin);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuperAdminDashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.key, size: 52, color: Color(0xFF114B7A)),
                        const SizedBox(height: 10),
                        Text(
                          'Reset Super Admin PIN',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(_otpSent ? 'Enter OTP and set a new PIN' : 'Login with email/password to get OTP'),
                        const SizedBox(height: 18),
                        if (!_otpSent) ...[
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _continueWithEmailPassword,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.arrow_forward),
                              label: Text(_loading ? 'Sending OTP...' : 'Continue'),
                            ),
                          ),
                        ] else ...[
                          if (_debugOtp != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Text(
                                'Dummy OTP: $_debugOtp',
                                style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'OTP (6 digits)',
                              prefixIcon: Icon(Icons.password),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _newPinController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'New PIN (4 digits)', counterText: ''),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _confirmPinController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Confirm PIN', counterText: ''),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _resetPin,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(_loading ? 'Resetting...' : 'Reset PIN'),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    try {
                                      final otp = await SuperAdminPinAuthService.sendPinResetOtp();
                                      if (!mounted) return;
                                      setState(() => _debugOtp = otp);
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text('OTP sent again')),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      setState(() => _error = e.toString());
                                    }
                                  },
                            child: const Text('Resend OTP'),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Color(0xFF991B1B)),
                            ),
                          ),
                        ],
                      ],
                    ),
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

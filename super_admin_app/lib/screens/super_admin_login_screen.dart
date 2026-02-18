import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/super_admin_pin_auth_service.dart';
import '../services/super_admin_service.dart';

class SuperAdminLoginScreen extends StatefulWidget {
  const SuperAdminLoginScreen({super.key});

  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    // Don't prefill credentials. Prefilling the wrong email/password can make it
    // look like login "doesn't go to dashboard" when auth never succeeds.
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) return;

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      debugPrint('[SuperAdminLogin] signInWithEmailAndPassword start');
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      debugPrint('[SuperAdminLogin] signInWithEmailAndPassword ok uid=${cred.user?.uid}');

      final access = await SuperAdminService.checkAccess(cred.user!.uid);
      if (!access.allowed) {
        debugPrint('[SuperAdminLogin] access denied: ${access.reason}');
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        setState(() => _errorText = access.reason);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(access.reason)),
        );
      } else {
        debugPrint('[SuperAdminLogin] access allowed');
        SuperAdminPinAuthService.markPinSetupAllowed();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.message ?? e.code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
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
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x33FFFFFF),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1FFFFFFF),
              ),
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              tween: Tween(begin: 0.95, end: 1.0),
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
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
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF114B7A), Color(0xFF1B998B)],
                              ),
                            ),
                            child: const Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Super Admin Login',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text('Manage all institutes, approvals and controls'),
                          const SizedBox(height: 18),
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
                              onPressed: _loading ? null : _login,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.login),
                              label: Text(_loading ? 'Signing In...' : 'Login'),
                            ),
                          ),
                          if (_errorText != null) ...[
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
                                _errorText!,
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
          ),
        ],
      ),
    );
  }
}

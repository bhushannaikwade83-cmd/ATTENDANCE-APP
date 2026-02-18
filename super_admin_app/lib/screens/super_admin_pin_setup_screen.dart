import 'package:flutter/material.dart';

import '../services/super_admin_pin_auth_service.dart';

class SuperAdminPinSetupScreen extends StatefulWidget {
  final bool isReset;
  final VoidCallback onPinSet;

  const SuperAdminPinSetupScreen({
    super.key,
    required this.onPinSet,
    this.isReset = false,
  });

  @override
  State<SuperAdminPinSetupScreen> createState() => _SuperAdminPinSetupScreenState();
}

class _SuperAdminPinSetupScreenState extends State<SuperAdminPinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      _show('PIN must be exactly 4 digits');
      return;
    }
    if (pin != confirm) {
      _show('PIN and confirm PIN must match');
      return;
    }

    setState(() => _saving = true);
    try {
      await SuperAdminPinAuthService.setPinForCurrentUser(pin);
      if (!mounted) return;
      widget.onPinSet();
    } catch (e) {
      if (!mounted) return;
      _show(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pin, size: 52, color: Color(0xFF114B7A)),
                      const SizedBox(height: 10),
                      Text(
                        widget.isReset ? 'Reset 4-Digit PIN' : 'Set 4-Digit PIN',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text('After this, super admin login will ask only PIN.'),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'New PIN', counterText: ''),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _confirmController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Confirm PIN', counterText: ''),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _savePin,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
                          label: Text(_saving ? 'Saving...' : 'Save PIN'),
                        ),
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


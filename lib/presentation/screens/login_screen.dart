import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import '../../services/auth_service.dart';
import '../../services/error_handler.dart';
import '../../services/pin_auth_service.dart';
import '../../core/theme/app_theme.dart';
import 'admin_home_screen.dart';
import 'institute_search_screen.dart';
import 'pin_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _showOtpField = false;
  int _otpTimeLeft = 60;
  Timer? _otpTimer;
  String? _currentUserId;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _fadeAnimation =
        Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _scaleAnimation =
        Tween(begin: 0.8, end: 1.0)
            .animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _otpTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _startOtpTimer() {
    _otpTimeLeft = 60;
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _otpTimeLeft--;
        if (_otpTimeLeft <= 0) timer.cancel();
      });
    });
  }

  Future<void> _sendOTP() async {
    setState(() => _isLoading = true);
    final result = await _authService.sendOTP(_currentUserId!);
    setState(() {
      _isLoading = false;
      _showOtpField = true;
    });
    _startOtpTimer();
    if (mounted) {
      _showSnackbar(
        result['success']
            ? 'OTP sent successfully'
            : result['message'],
        result['success'],
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!result['success']) {
      setState(() => _isLoading = false);
      _showSnackbar(result['message'], false);
      return;
    }

    _currentUserId = result['userId'];

    if (!_showOtpField) {
      setState(() => _isLoading = false);
      await _sendOTP();
      return;
    }

    final otpResult = await _authService.verifyOTP(
      userId: _currentUserId!,
      otp: _otpController.text.trim(),
    );

    if (!otpResult['success']) {
      setState(() => _isLoading = false);
      _showSnackbar(otpResult['message'], false);
      return;
    }

    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
    );
  }

  void _showSnackbar(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            success ? AppTheme.primaryGreen : AppTheme.accentRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlueDark,
              AppTheme.primaryBlueLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [

                    const SizedBox(height: 40),

                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.fingerprint,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "EduSetu",
                            style: TextStyle(
                              fontSize: 34,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [

                          _buildTextField(
                            controller: _emailController,
                            label: "Email",
                            icon: Icons.email,
                          ),

                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _passwordController,
                            label: "Password",
                            icon: Icons.lock,
                            isPassword: true,
                          ),

                          if (_showOtpField) ...[
                            const SizedBox(height: 16),
                            _buildOTPField(),
                          ],

                          const SizedBox(height: 30),

                          _buildLoginButton(),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "$label required" : null,
    );
  }

  Widget _buildOTPField() {
    return TextFormField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 20),
      decoration: InputDecoration(
        labelText: "Enter OTP",
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryBlue,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: _isLoading
          ? const CircularProgressIndicator()
          : Text(_showOtpField ? "Verify & Login" : "Login"),
    );
  }
}

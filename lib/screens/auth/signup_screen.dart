import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/utils.dart';
import '../../core/app_colors.dart';
import '../../services/firebase_auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  bool _loading = false;
  bool _agreeToTerms = false;

  // Randomized neon color palette for signup (cyan/teal instead of magenta)
  final Color _accentColor = const Color(0xFF00D9FF); // Cyan
  final Color _gradientStart = const Color(0xFF00D9FF);
  final Color _gradientEnd = const Color(0xFF0099FF);

  void _signup() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final pass = _password.text;
    final confirmPass = _confirmPassword.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirmPass.isEmpty) {
      Utils.showSnackbar(context, "Please fill all fields", error: true);
      return;
    }

    if (pass != confirmPass) {
      Utils.showSnackbar(context, "Passwords do not match", error: true);
      return;
    }

    if (!_agreeToTerms) {
      Utils.showSnackbar(context, "Please agree to terms & conditions", error: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final authService = AuthService();
      await authService.signUp(email, pass, name);
      
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pushReplacementNamed(context, AppRoutes.profileChoice);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      Utils.showSnackbar(context, "Signup failed: ${e.toString()}", error: true);
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  OutlineInputBorder _neonBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: _accentColor.withValues(alpha: 0.9), width: 1.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Decorative faint circles
          Positioned(
            top: -60,
            right: -60,
            child: Opacity(
              opacity: 0.06,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Opacity(
              opacity: 0.06,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _goToLogin,
                      ),
                    ),

                    // Headline
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join the network of legends.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 28),

                    // Name field
                    _NeonTextField(
                      controller: _name,
                      hintText: 'Full Name',
                      obscureText: false,
                      border: _neonBorder(),
                      accentColor: _accentColor,
                    ),
                    const SizedBox(height: 16),

                    // Email field
                    _NeonTextField(
                      controller: _email,
                      hintText: 'Email',
                      obscureText: false,
                      border: _neonBorder(),
                      accentColor: _accentColor,
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    _NeonTextField(
                      controller: _password,
                      hintText: 'Password',
                      obscureText: true,
                      border: _neonBorder(),
                      accentColor: _accentColor,
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password field
                    _NeonTextField(
                      controller: _confirmPassword,
                      hintText: 'Confirm Password',
                      obscureText: true,
                      border: _neonBorder(),
                      accentColor: _accentColor,
                    ),

                    const SizedBox(height: 16),

                    // Terms & Conditions checkbox
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreeToTerms,
                            onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                            side: BorderSide(color: _accentColor.withValues(alpha: 0.9), width: 1.5),
                            fillColor: WidgetStatePropertyAll(_accentColor.withValues(alpha: 0.3)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: 'I agree to ', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                                TextSpan(text: 'Terms & Conditions', style: TextStyle(color: _accentColor)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Signup button
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 6,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [_gradientStart, _gradientEnd]),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: _accentColor.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                                : const Text('Sign Up', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Already have account
                    GestureDetector(
                      onTap: _goToLogin,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: 'Already have an account? ', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                            TextSpan(text: 'Log In', style: TextStyle(color: _accentColor)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }
}

class _NeonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final OutlineInputBorder border;
  final Color accentColor;

  const _NeonTextField({
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.border,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: accentColor.withValues(alpha: 0.9)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: border.copyWith(borderSide: BorderSide(color: accentColor.withValues(alpha: 0.9), width: 1.8)),
        focusedBorder: border.copyWith(borderSide: BorderSide(color: accentColor, width: 2.2)),
      ),
    );
  }
}
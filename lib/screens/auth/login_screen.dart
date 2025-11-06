import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/utils.dart';
import '../../core/app_colors.dart';
import '../../services/firebase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;

  void _login() async {
    final email = _email.text.trim();
    final pass = _password.text;
    if (email.isEmpty || pass.isEmpty) {
      Utils.showSnackbar(context, "Please enter email & password", error: true);
      return;
    }
    setState(() => _loading = true);

    try {
      final authService = AuthService();
      await authService.signIn(email, pass);
      
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      Utils.showSnackbar(context, "Login failed: ${e.toString()}", error: true);
    }
  }

  void _goToSignup() {
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.signup);
  }

  OutlineInputBorder _neonBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: const BorderSide(color: Color(0xFF8A2BE2), width: 2.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Decorative faint circles (simple implementation)
          Positioned(
            top: -60,
            left: -60,
            child: Opacity(
              opacity: 0.06,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Opacity(
              opacity: 0.06,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App Title
                    Text(
                      'Rizzume',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFB57BFF).withValues(alpha: 0.9),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Headline
                    const Text(
                      "Let's get it.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome back, homie!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 28),

                    // Email field
                    _NeonTextField(
                      controller: _email,
                      hintText: 'Email or Username',
                      obscureText: false,
                      border: _neonBorder(),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    _NeonTextField(
                      controller: _password,
                      hintText: 'Password',
                      obscureText: true,
                      border: _neonBorder(),
                    ),

                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(color: Colors.purple.shade200),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 6,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFDA3BFF), Color(0xFF9B4CFF)]),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9B4CFF).withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                                : const Text('Log In', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Or divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.white.withValues(alpha: 0.15), thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Or vibe with', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                        ),
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15), thickness: 1)),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Social buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _OutlinedSocialButton(
                            label: 'Google',
                            icon: Icons.g_mobiledata,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _OutlinedSocialButton(
                            label: 'Apple',
                            icon: Icons.apple,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.08),

                    GestureDetector(
                      onTap: _goToSignup,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: 'No account? ', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                            TextSpan(text: 'Slide into the DMs', style: TextStyle(color: const Color(0xFFDA3BFF))),
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
}

class _NeonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final OutlineInputBorder border;

  const _NeonTextField({required this.controller, required this.hintText, required this.obscureText, required this.border});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.purple.shade200.withValues(alpha: 0.9)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: border.copyWith(borderSide: BorderSide(color: Colors.purple.shade300.withValues(alpha: 0.9), width: 1.8)),
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: Color(0xFFDA3BFF), width: 2.2)),
      ),
    );
  }
}

class _OutlinedSocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _OutlinedSocialButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.9), width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
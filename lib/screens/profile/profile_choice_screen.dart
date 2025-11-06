import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/app_colors.dart';

class ProfileChoiceScreen extends StatelessWidget {
  const ProfileChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Decorative circles
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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Choose Profile Type',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start with a personal or job profile.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Personal Profile Option
                  Expanded(
                    child: _ProfileCard(
                      title: 'Personal Profile',
                      subtitle: 'Showcase your interests, photos & bio',
                      icon: Icons.person,
                      accentColor: const Color(0xFFDA3BFF), // Magenta
                      onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.personalProfile),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Job Profile Option
                  Expanded(
                    child: _ProfileCard(
                      title: 'Job Profile',
                      subtitle: 'Add experience, education & skills',
                      icon: Icons.work,
                      accentColor: const Color(0xFF00FF88), // Lime green
                      onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.jobProfile),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Skip option
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                      child: Text(
                        'Skip for now',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: accentColor.withValues(alpha: 0.8), width: 2),
          borderRadius: BorderRadius.circular(20),
          color: accentColor.withValues(alpha: 0.05),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentColor, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

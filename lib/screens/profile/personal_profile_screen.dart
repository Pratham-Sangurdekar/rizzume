import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/app_colors.dart';
import '../../services/firebase_firestore_service.dart';
import '../../core/utils.dart';

class PersonalProfileScreen extends StatefulWidget {
  const PersonalProfileScreen({super.key});

  @override
  State<PersonalProfileScreen> createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends State<PersonalProfileScreen> {
  final TextEditingController _bioController = TextEditingController();
  final List<String> _interests = [];
  final List<String> _availableInterests = ['Gaming', 'Music', 'Travel', 'Art', 'Foodie', 'Fitness', 'Sports', 'Reading'];

  final Color _accentColor = const Color(0xFFDA3BFF); // Magenta

  OutlineInputBorder _neonBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: _accentColor.withValues(alpha: 0.8), width: 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        'Create Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(width: 48), // Placeholder for balance
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Interests Section
                  Text(
                    'Interests',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _availableInterests.map((interest) {
                      final isSelected = _interests.contains(interest);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _interests.remove(interest);
                            } else {
                              _interests.add(interest);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? _accentColor : _accentColor.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            color: isSelected ? _accentColor.withValues(alpha: 0.2) : Colors.transparent,
                          ),
                          child: Text(
                            interest,
                            style: TextStyle(
                              color: isSelected ? _accentColor : Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Photos Section
                  Text(
                    'Photos',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _PhotoPlaceholder(color: _accentColor),
                      _PhotoPlaceholder(color: const Color(0xFF00D9FF)),
                      _PhotoPlaceholder(color: const Color(0xFFFFD700)),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Bio Section
                  Text(
                    'Bio',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _bioController,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tell us about yourself...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.02),
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: _neonBorder(),
                      focusedBorder: _neonBorder().copyWith(
                        borderSide: BorderSide(color: _accentColor, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Let's Go button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final firestoreService = FirestoreService();
                          await firestoreService.savePersonalProfile(
                            interests: _interests,
                            bio: _bioController.text.trim(),
                          );
                          if (!context.mounted) return;
                          Navigator.pushReplacementNamed(context, AppRoutes.home);
                        } catch (e) {
                          if (!context.mounted) return;
                          Utils.showSnackbar(context, "Failed to save profile: ${e.toString()}", error: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        elevation: 6,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [_accentColor, _accentColor.withValues(alpha: 0.7)]),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "Let's Go!",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final Color color;

  const _PhotoPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2.5, strokeAlign: BorderSide.strokeAlignOutside),
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Center(
          child: Icon(Icons.add, color: color, size: 40),
        ),
      ),
    );
  }
}

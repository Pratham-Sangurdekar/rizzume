import 'package:flutter/material.dart';
import '../../services/firebase_firestore_service.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';

class EditPersonalScreen extends StatefulWidget {
  const EditPersonalScreen({super.key});

  @override
  State<EditPersonalScreen> createState() => _EditPersonalScreenState();
}

class _EditPersonalScreenState extends State<EditPersonalScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _bioController = TextEditingController();
  final List<String> _selectedInterests = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final Color _accentColor = const Color(0xFFDA3BFF); // Magenta

  final List<String> _availableInterests = [
    'Gaming', 'Music', 'Travel', 'Art', 'Foodie', 
    'Fitness', 'Sports', 'Reading', 'Photography', 'Technology',
    'Movies', 'Fashion', 'Cooking', 'Nature', 'Business',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _firestoreService.getCurrentUserData();
      if (userData != null) {
        final personalProfile = userData['personalProfile'] as Map<String, dynamic>?;
        if (personalProfile != null) {
          setState(() {
            _bioController.text = personalProfile['bio'] ?? '';
            _selectedInterests.clear();
            _selectedInterests.addAll(
              List<String>.from(personalProfile['interests'] ?? []),
            );
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (!mounted) return;
      Utils.showSnackbar(context, 'Failed to load profile data', error: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_bioController.text.trim().isEmpty) {
      Utils.showSnackbar(context, 'Please add a bio', error: true);
      return;
    }

    if (_selectedInterests.isEmpty) {
      Utils.showSnackbar(context, 'Please select at least one interest', error: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _firestoreService.savePersonalProfile(
        interests: _selectedInterests,
        bio: _bioController.text.trim(),
      );

      if (!mounted) return;
      Utils.showSnackbar(context, 'Profile updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      print('Error saving profile: $e');
      if (!mounted) return;
      Utils.showSnackbar(context, 'Failed to save profile: ${e.toString()}', error: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

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
          // Decorative circles
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
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button + header
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            Text(
                              'Edit Personal Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(width: 48), // Balance
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
                            final isSelected = _selectedInterests.contains(interest);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedInterests.remove(interest);
                                  } else {
                                    _selectedInterests.add(interest);
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

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
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
                              child: Center(
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text(
                                        "Save Changes",
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

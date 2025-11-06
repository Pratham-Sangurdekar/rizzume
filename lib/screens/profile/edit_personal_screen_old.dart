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

  final List<String> _availableInterests = [
    'Technology',
    'Sports',
    'Music',
    'Travel',
    'Food',
    'Photography',
    'Reading',
    'Gaming',
    'Fitness',
    'Art',
    'Movies',
    'Fashion',
    'Cooking',
    'Nature',
    'Business',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('Edit Personal Profile', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bio section
                  const Text(
                    'Bio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bioController,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tell us about yourself...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Interests section
                  const Text(
                    'Interests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select at least one interest',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableInterests.map((interest) {
                      final isSelected = _selectedInterests.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedInterests.add(interest);
                            } else {
                              _selectedInterests.remove(interest);
                            }
                          });
                        },
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        selectedColor: const Color(0xFF6C63FF),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                        ),
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../core/app_colors.dart';
import '../../services/firebase_firestore_service.dart';
import '../../core/utils.dart';

class JobProfileScreen extends StatefulWidget {
  const JobProfileScreen({super.key});

  @override
  State<JobProfileScreen> createState() => _JobProfileScreenState();
}

class _JobProfileScreenState extends State<JobProfileScreen> {
  final Color _accentColor = const Color(0xFF00FF88); // Lime green

  // Experience
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Education
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _fieldController = TextEditingController();
  final TextEditingController _graduationController = TextEditingController();

  // Skills
  final TextEditingController _skillsController = TextEditingController();

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
            left: -60,
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
                  // Back button + header
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
                      SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Experience Section
                  Text(
                    'Experience',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _NeonTextField(
                    controller: _jobTitleController,
                    hintText: 'Job Title',
                    border: _neonBorder(),
                    accentColor: _accentColor,
                  ),
                  const SizedBox(height: 12),

                  _NeonTextField(
                    controller: _companyController,
                    hintText: 'Company',
                    border: _neonBorder(),
                    accentColor: _accentColor,
                  ),
                  const SizedBox(height: 12),

                  _NeonTextField(
                    controller: _locationController,
                    hintText: 'Location',
                    border: _neonBorder(),
                    accentColor: _accentColor,
                  ),
                  const SizedBox(height: 12),

                  // Date fields side by side
                  Row(
                    children: [
                      Expanded(
                        child: _NeonTextField(
                          controller: _startDateController,
                          hintText: 'Start Date',
                          border: _neonBorder(),
                          accentColor: _accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NeonTextField(
                          controller: _endDateController,
                          hintText: 'End Date',
                          border: _neonBorder(),
                          accentColor: _accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _NeonTextField(
                    controller: _descriptionController,
                    hintText: 'Description',
                    border: _neonBorder(),
                    accentColor: _accentColor,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 32),

                  // Education Section
                  Text(
                    'Education',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _NeonTextField(
                    controller: _schoolController,
                    hintText: 'School',
                    border: _neonBorder(),
                    accentColor: _accentColor,
                  ),
                  const SizedBox(height: 12),

                  _NeonTextField(
                    controller: _degreeController,
                    hintText: 'Degree',
                    border: _neonBorder(),
                    accentColor: _accentColor,
                  ),
                  const SizedBox(height: 12),

                  _NeonTextField(
                    controller: _fieldController,
                    hintText: 'Field of Study',
                    border: _neonBorder(),
                    accentColor: _accentColor,
                  ),
                  const SizedBox(height: 12),

                  _NeonTextField(
                    controller: _graduationController,
                    hintText: 'Graduation Date',
                    border: _neonBorder(),
                    accentColor: _accentColor,
                  ),

                  const SizedBox(height: 32),

                  // Skills Section
                  Text(
                    'Skills',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _NeonTextField(
                    controller: _skillsController,
                    hintText: 'Add Skills (e.g., UI/UX Design, Swift, Marketing)',
                    border: _neonBorder(),
                    accentColor: _accentColor,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),

                  // Upload Resume button
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, color: Colors.white.withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Text(
                            'Upload Resume',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Finish button (neon glow effect)
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final firestoreService = FirestoreService();
                          await firestoreService.saveJobProfile(
                            jobTitle: _jobTitleController.text.trim(),
                            company: _companyController.text.trim(),
                            location: _locationController.text.trim(),
                            startDate: _startDateController.text.trim(),
                            endDate: _endDateController.text.trim(),
                            description: _descriptionController.text.trim(),
                            school: _schoolController.text.trim(),
                            degree: _degreeController.text.trim(),
                            fieldOfStudy: _fieldController.text.trim(),
                            graduationDate: _graduationController.text.trim(),
                            skills: _skillsController.text.trim(),
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
                            "Finish",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
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
    _jobTitleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    _schoolController.dispose();
    _degreeController.dispose();
    _fieldController.dispose();
    _graduationController.dispose();
    _skillsController.dispose();
    super.dispose();
  }
}

class _NeonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final OutlineInputBorder border;
  final Color accentColor;
  final int maxLines;

  const _NeonTextField({
    required this.controller,
    required this.hintText,
    required this.border,
    required this.accentColor,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: accentColor.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: border.copyWith(borderSide: BorderSide(color: accentColor.withValues(alpha: 0.8), width: 1.5)),
        focusedBorder: border.copyWith(borderSide: BorderSide(color: accentColor, width: 2)),
      ),
    );
  }
}

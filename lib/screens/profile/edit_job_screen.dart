import 'package:flutter/material.dart';
import '../../services/firebase_firestore_service.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';

class EditJobScreen extends StatefulWidget {
  const EditJobScreen({super.key});

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Color _accentColor = const Color(0xFF00FF88); // Lime green
  
  // Experience controllers
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Education controllers
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _fieldOfStudyController = TextEditingController();
  final TextEditingController _graduationDateController = TextEditingController();
  
  // Skills controller
  final TextEditingController _skillsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _firestoreService.getCurrentUserData();
      if (userData != null) {
        final jobProfile = userData['jobProfile'] as Map<String, dynamic>?;
        if (jobProfile != null) {
          final experience = jobProfile['experience'] as Map<String, dynamic>?;
          final education = jobProfile['education'] as Map<String, dynamic>?;
          
          setState(() {
            // Experience
            _jobTitleController.text = experience?['jobTitle'] ?? '';
            _companyController.text = experience?['company'] ?? '';
            _locationController.text = experience?['location'] ?? '';
            _startDateController.text = experience?['startDate'] ?? '';
            _endDateController.text = experience?['endDate'] ?? '';
            _descriptionController.text = experience?['description'] ?? '';
            
            // Education
            _schoolController.text = education?['school'] ?? '';
            _degreeController.text = education?['degree'] ?? '';
            _fieldOfStudyController.text = education?['fieldOfStudy'] ?? '';
            _graduationDateController.text = education?['graduationDate'] ?? '';
            
            // Skills
            _skillsController.text = jobProfile['skills'] ?? '';
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
    if (_jobTitleController.text.trim().isEmpty) {
      Utils.showSnackbar(context, 'Please add a job title', error: true);
      return;
    }

    if (_schoolController.text.trim().isEmpty) {
      Utils.showSnackbar(context, 'Please add your school', error: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _firestoreService.saveJobProfile(
        jobTitle: _jobTitleController.text.trim(),
        company: _companyController.text.trim(),
        location: _locationController.text.trim(),
        startDate: _startDateController.text.trim(),
        endDate: _endDateController.text.trim(),
        description: _descriptionController.text.trim(),
        school: _schoolController.text.trim(),
        degree: _degreeController.text.trim(),
        fieldOfStudy: _fieldOfStudyController.text.trim(),
        graduationDate: _graduationDateController.text.trim(),
        skills: _skillsController.text.trim(),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: _accentColor.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: _neonBorder(),
        focusedBorder: _neonBorder().copyWith(
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
      ),
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
                              'Edit Job Profile',
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

                        _buildTextField(
                          controller: _jobTitleController,
                          hintText: 'Job Title',
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _companyController,
                          hintText: 'Company',
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _locationController,
                          hintText: 'Location',
                        ),
                        const SizedBox(height: 12),

                        // Date fields side by side
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _startDateController,
                                hintText: 'Start Date',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _endDateController,
                                hintText: 'End Date',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _descriptionController,
                          hintText: 'Description',
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

                        _buildTextField(
                          controller: _schoolController,
                          hintText: 'School',
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _degreeController,
                          hintText: 'Degree',
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _fieldOfStudyController,
                          hintText: 'Field of Study',
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _graduationDateController,
                          hintText: 'Graduation Date',
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

                        _buildTextField(
                          controller: _skillsController,
                          hintText: 'Add Skills (e.g., UI/UX Design, Swift, Marketing)',
                          maxLines: 2,
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
                                        child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2),
                                      )
                                    : const Text(
                                        "Save Changes",
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
    _fieldOfStudyController.dispose();
    _graduationDateController.dispose();
    _skillsController.dispose();
    super.dispose();
  }
}

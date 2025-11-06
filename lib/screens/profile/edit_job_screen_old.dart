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
            // Load experience
            if (experience != null) {
              _jobTitleController.text = experience['jobTitle'] ?? '';
              _companyController.text = experience['company'] ?? '';
              _locationController.text = experience['location'] ?? '';
              _startDateController.text = experience['startDate'] ?? '';
              _endDateController.text = experience['endDate'] ?? '';
              _descriptionController.text = experience['description'] ?? '';
            }
            
            // Load education
            if (education != null) {
              _schoolController.text = education['school'] ?? '';
              _degreeController.text = education['degree'] ?? '';
              _fieldOfStudyController.text = education['fieldOfStudy'] ?? '';
              _graduationDateController.text = education['graduationDate'] ?? '';
            }
            
            // Load skills
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
    // Validate required fields
    if (_jobTitleController.text.trim().isEmpty) {
      Utils.showSnackbar(context, 'Please enter your job title', error: true);
      return;
    }
    if (_schoolController.text.trim().isEmpty) {
      Utils.showSnackbar(context, 'Please enter your school', error: true);
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
      Utils.showSnackbar(context, 'Job profile updated successfully!');
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint ?? label,
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('Edit Job Profile', style: TextStyle(color: Colors.white)),
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
                  // Experience Section
                  const Text(
                    'Experience',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _jobTitleController,
                    label: 'Job Title *',
                    hint: 'e.g., Software Engineer',
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _companyController,
                    label: 'Company',
                    hint: 'e.g., Google',
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _locationController,
                    label: 'Location',
                    hint: 'e.g., San Francisco, CA',
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _startDateController,
                          label: 'Start Date',
                          hint: 'e.g., Jan 2023',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _endDateController,
                          label: 'End Date',
                          hint: 'e.g., Present',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Describe your role and achievements...',
                    maxLines: 4,
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 32),

                  // Education Section
                  const Text(
                    'Education',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _schoolController,
                    label: 'School *',
                    hint: 'e.g., Stanford University',
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _degreeController,
                    label: 'Degree',
                    hint: 'e.g., Bachelor of Science',
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _fieldOfStudyController,
                    label: 'Field of Study',
                    hint: 'e.g., Computer Science',
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _graduationDateController,
                    label: 'Graduation Date',
                    hint: 'e.g., May 2022',
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 32),

                  // Skills Section
                  const Text(
                    'Skills',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _skillsController,
                    label: 'Skills',
                    hint: 'e.g., Python, JavaScript, React, Machine Learning',
                    maxLines: 3,
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
                  const SizedBox(height: 20),
                ],
              ),
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

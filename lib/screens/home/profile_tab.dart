import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// auth service moved to settings; not required here
import '../../services/firebase_firestore_service.dart';
// ...existing imports...
import '../../core/utils.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // AuthService not needed here; actions moved to SettingsScreen
  final FirestoreService _firestoreService = FirestoreService();
  File? _avatar;
  String? _profilePictureBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    try {
      final userData = await _firestoreService.getCurrentUserData();
      if (userData != null && userData['profilePicture'] != null) {
        setState(() {
          _profilePictureBase64 = userData['profilePicture'];
        });
      }
    } catch (e) {
      print('Error loading profile picture: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 60,
    );
    if (picked == null) return;

    setState(() {
      _avatar = File(picked.path);
      _isLoading = true;
    });

    try {
      // Convert to base64
      final bytes = await File(picked.path).readAsBytes();
      
      // Check file size
      if (bytes.length > 900000) {
        if (!mounted) return;
        Utils.showSnackbar(context, "Image is too large. Please choose a smaller image.", error: true);
        setState(() {
          _avatar = null;
          _isLoading = false;
        });
        return;
      }

      final base64Image = base64Encode(bytes);
      
      // Save to Firestore
      await _firestoreService.updateProfilePicture(base64Image);
      
      setState(() {
        _profilePictureBase64 = base64Image;
        _isLoading = false;
      });
      
      if (!mounted) return;
      Utils.showSnackbar(context, "Profile picture updated successfully!");
    } catch (e) {
      print('Error uploading profile picture: $e');
      if (!mounted) return;
      setState(() {
        _avatar = null;
        _isLoading = false;
      });
      Utils.showSnackbar(context, "Failed to update profile picture: ${e.toString()}", error: true);
    }
  }

  // Logout handled in Settings screen

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Top half container to center avatar
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.36,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: _avatar != null
                            ? FileImage(_avatar!)
                            : _profilePictureBase64 != null
                                ? MemoryImage(base64Decode(_profilePictureBase64!))
                                : null,
                        child: _avatar == null && _profilePictureBase64 == null
                            ? const Icon(Icons.camera_alt, color: Colors.white54, size: 36)
                            : null,
                      ),
                      if (_isLoading)
                        Positioned.fill(
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: Colors.black54,
                            child: const CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to change profile picture',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                ),
              ],
            ),
          ),

          // Note: Profile actions (edit/logout) moved to Settings page
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_colors.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/media_upload_service.dart';
import '../../core/utils.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final MediaUploadService _mediaService = MediaUploadService();
  bool _isPosting = false;
  XFile? _pickedImage;
  XFile? _pickedVideo;
  VideoPlayerController? _videoController;
  String _uploadProgress = '';

  final Color _accentColor = const Color(0xFFFF1493); // Deep pink

  Future<void> _post() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _pickedImage == null) {
      Utils.showSnackbar(context, "Please add text or an image to post", error: true);
      return;
    }

    setState(() => _isPosting = true);

    try {
      String? imageBase64;
      String? videoUrl;
      String? thumbnailUrl;
      int? videoDuration;
      
      // Handle video upload
      if (_pickedVideo != null) {
        try {
          setState(() => _uploadProgress = 'Compressing video...');
          
          final result = await _mediaService.uploadVideoWithThumbnail(File(_pickedVideo!.path));
          
          videoUrl = result['videoUrl'];
          thumbnailUrl = result['thumbnailUrl'];
          videoDuration = int.tryParse(result['duration'] ?? '0');
          
          setState(() => _uploadProgress = 'Uploading video...');
        } catch (e) {
          print('❌ Error uploading video: $e');
          if (!mounted) return;
          setState(() {
            _isPosting = false;
            _uploadProgress = '';
          });
          Utils.showSnackbar(context, "Failed to upload video: ${e.toString()}", error: true);
          return;
        }
      }
      
      // Convert image to base64 if selected
      if (_pickedImage != null) {
        try {
          final file = File(_pickedImage!.path);
          final bytes = await file.readAsBytes();
          
          // Check file size (Firestore has 1MB document limit)
          if (bytes.length > 900000) { // ~900KB to be safe
            if (!mounted) return;
            setState(() => _isPosting = false);
            Utils.showSnackbar(context, "Image is too large. Please choose a smaller image (max ~900KB).", error: true);
            return;
          }
          
          imageBase64 = base64Encode(bytes);
        } catch (e) {
          print('❌ Error reading image: $e');
          if (!mounted) return;
          setState(() => _isPosting = false);
          Utils.showSnackbar(context, "Failed to process image. Please try a different image.", error: true);
          return;
        }
      }

      setState(() => _uploadProgress = 'Creating post...');

      // Create post in Firestore
      final firestoreService = FirestoreService();
      await firestoreService.createPost(
        content: content,
        imageUrl: imageBase64,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        duration: videoDuration,
      );

      if (!mounted) return;
      Navigator.pop(context);
      Utils.showSnackbar(context, "Post created successfully!");
    } catch (e) {
      print('❌ Error creating post: $e');
      if (!mounted) return;
      setState(() {
        _isPosting = false;
        _uploadProgress = '';
      });
      Utils.showSnackbar(context, "Failed to create post: ${e.toString()}", error: true);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 60,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
        // Clear video if image is picked
        _pickedVideo = null;
        _videoController?.dispose();
        _videoController = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    
    if (pickedFile == null) return;
    
    try {
      // Check video duration
      final duration = await _mediaService.getVideoDuration(pickedFile.path);
      
      if (duration > 120) {
        if (mounted) {
          Utils.showSnackbar(
            context,
            "Video must be under 2 minutes (current: ${duration}s)",
            error: true,
          );
        }
        return;
      }
      
      // Initialize video controller for preview
      final controller = VideoPlayerController.file(File(pickedFile.path));
      await controller.initialize();
      
      setState(() {
        _pickedVideo = pickedFile;
        _videoController = controller;
        // Clear image if video is picked
        _pickedImage = null;
      });
    } catch (e) {
      if (mounted) {
        Utils.showSnackbar(context, "Error loading video: $e", error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Post',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _post,
            child: _isPosting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: _accentColor,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Post',
                    style: TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content input
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Media picker area
            if (_pickedImage != null)
              // Image preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: _accentColor.withValues(alpha: 0.3), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_pickedImage!.path), width: 84, height: 84, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Photo attached',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _pickedImage = null),
                      icon: const Icon(Icons.delete, color: Colors.white),
                    ),
                  ],
                ),
              )
            else if (_pickedVideo != null && _videoController != null)
              // Video preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: _accentColor.withValues(alpha: 0.3), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 84,
                            height: 84,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                        Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Video attached',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                          ),
                          Text(
                            'Duration: ${_videoController!.value.duration.inSeconds}s',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _videoController?.dispose();
                        setState(() {
                          _pickedVideo = null;
                          _videoController = null;
                        });
                      },
                      icon: const Icon(Icons.delete, color: Colors.white),
                    ),
                  ],
                ),
              )
            else
              // Picker buttons (no media selected)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: _accentColor.withValues(alpha: 0.3), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, color: _accentColor.withValues(alpha: 0.7)),
                            const SizedBox(width: 8),
                            Text(
                              'Photo',
                              style: TextStyle(
                                color: _accentColor.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickVideo,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: _accentColor.withValues(alpha: 0.3), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam, color: _accentColor.withValues(alpha: 0.7)),
                            const SizedBox(width: 8),
                            Text(
                              'Video',
                              style: TextStyle(
                                color: _accentColor.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Upload progress indicator
            if (_uploadProgress.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _uploadProgress,
                  style: TextStyle(
                    color: _accentColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}

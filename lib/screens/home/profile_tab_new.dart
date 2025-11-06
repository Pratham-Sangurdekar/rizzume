import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';

class ProfileTabNew extends StatefulWidget {
  const ProfileTabNew({super.key});

  @override
  State<ProfileTabNew> createState() => _ProfileTabNewState();
}

class _ProfileTabNewState extends State<ProfileTabNew> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  File? _avatar;
  String? _profilePictureBase64;
  bool _isLoading = false;
  bool _isPersonalView = true; // Toggle: true = Personal, false = Professional
  
  Map<String, dynamic>? _userData;
  List<QueryDocumentSnapshot> _userPosts = [];
  int _followerCount = 0;
  int _followingCount = 0;
  int _connectionCount = 0;
  int _postCount = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isPersonalView = _tabController.index == 0;
      });
    });
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final uid = _authService.currentUser?.uid;
      if (uid == null) return;

      // Initialize stats fields if they don't exist
      await _firestoreService.initializeUserStats(uid);

      final userData = await _firestoreService.getCurrentUserData();
      
      if (userData != null) {
        // Load user posts (without orderBy to avoid index requirement)
        final postsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: uid)
            .get();

        // Sort posts in memory by createdAt
        final sortedPosts = postsSnapshot.docs.toList()
          ..sort((a, b) {
            final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime); // Descending order (newest first)
          });

        setState(() {
          _userData = userData;
          _profilePictureBase64 = userData['profilePicture'];
          _userPosts = sortedPosts;
          _postCount = sortedPosts.length;
          
          // Load stats (using existing or default values)
          _followerCount = userData['followerCount'] ?? 0;
          _followingCount = userData['followingCount'] ?? 0;
          _connectionCount = userData['connectionCount'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
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
      final bytes = await File(picked.path).readAsBytes();
      
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
      Utils.showSnackbar(context, "Failed to update profile picture", error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with toggle
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                children: [
                  // Toggle between Personal and Professional (40% smaller)
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF9D4EDD), Color(0xFF7B2CBF)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.5),
                        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        tabs: [
                          Tab(text: 'Personal'),
                          Tab(text: 'Professional'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // Profile Picture (smaller size)
                GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF9D4EDD), Color(0xFF7B2CBF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF9D4EDD).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          radius: 47,
                          backgroundColor: AppColors.darkBackground,
                          backgroundImage: _profilePictureBase64 != null && _profilePictureBase64!.isNotEmpty
                              ? MemoryImage(base64Decode(_profilePictureBase64!))
                              : _avatar != null
                                  ? FileImage(_avatar!)
                                  : null,
                          child: (_profilePictureBase64 == null || _profilePictureBase64!.isEmpty) && _avatar == null
                              ? const Icon(Icons.camera_alt, color: Colors.white54, size: 32)
                              : null,
                        ),
                      ),
                      if (_isLoading)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                          ),
                          child: const CircularProgressIndicator(color: Colors.white),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // User Name
                Text(
                  _userData?['name'] ?? 'User Name',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Bio (show actual user bio)
                if (_userData != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        if (_isPersonalView)
                          Text(
                            _userData?['personalProfile']?['bio']?.toString() ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          )
                        else
                          Text(
                            _userData?['jobProfile']?['experience']?['jobTitle']?.toString() ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Interests Tags (only for personal view)
                if (_isPersonalView && _userData?['personalProfile']?['interests'] != null && 
                    (_userData?['personalProfile']?['interests'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List<String>.from(_userData?['personalProfile']?['interests'] ?? [])
                          .map((interest) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color.fromARGB(255, 22, 185, 255).withOpacity(0.6), width: 1.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  interest,
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                
                // Add spacing after interests if they exist
                if (_isPersonalView && _userData?['personalProfile']?['interests'] != null && 
                    (_userData?['personalProfile']?['interests'] as List).isNotEmpty)
                  const SizedBox(height: 16),
                
                const SizedBox(height: 20),
                
                // Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _buildStatCard('$_followerCount', 'Followers')),
                      SizedBox(width: 8),
                      Expanded(child: _buildStatCard('$_postCount', 'Posts')),
                      SizedBox(width: 8),
                      Expanded(child: _buildStatCard('$_followingCount', 'Following')),
                      SizedBox(width: 8),
                      Expanded(child: _buildStatCard('$_connectionCount', 'Connections')),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Posts Grid (3 columns) or Empty State
          if (_userPosts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No posts yet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = _userPosts[index];
                    final postData = post.data() as Map<String, dynamic>;
                    return _buildPostThumbnail(postData);
                  },
                  childCount: _userPosts.length,
                ),
              ),
            ),
          
          // Bottom padding for floating deck
          SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPostThumbnail(Map<String, dynamic> postData) {
    final imageUrl = postData['imageUrl'] as String?;
    final videoUrl = postData['videoUrl'] as String?;
    final thumbnailUrl = postData['thumbnailUrl'] as String?;
    final content = postData['content'] as String? ?? '';

    // Video post - show thumbnail with video icon overlay
    if (videoUrl != null && videoUrl.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                  ? Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.black,
                        child: Icon(
                          Icons.videocam,
                          color: Colors.white.withOpacity(0.5),
                          size: 32,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.black,
                      child: Icon(
                        Icons.videocam,
                        color: Colors.white.withOpacity(0.5),
                        size: 32,
                      ),
                    ),
            ),
          ),
          // Video icon overlay in top-right corner
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      );
    }
    
    // Image post - show image thumbnail
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl.startsWith('data:') || imageUrl.startsWith('http')
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _buildTextThumbnail(content),
                )
              : Image.memory(
                  base64Decode(imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _buildTextThumbnail(content),
                ),
        ),
      );
    } else {
      // Text-only post - show text preview
      return _buildTextThumbnail(content);
    }
  }

  Widget _buildTextThumbnail(String content) {
    // Random dopamine-high solid colors with low opacity for text posts
    final colors = [
      Color(0xFFFF006E).withOpacity(0.25), // Hot pink
      Color(0xFF7B2CBF).withOpacity(0.25), // Purple
      Color(0xFF00D9FF).withOpacity(0.25), // Cyan
      Color(0xFFFFD60A).withOpacity(0.25), // Yellow
      Color(0xFFFF5400).withOpacity(0.25), // Orange
      Color(0xFF0077B6).withOpacity(0.25), // Blue
    ];
    final color = colors[content.length % colors.length];

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Text(
          content.length > 80 ? content.substring(0, 80) + '...' : content,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

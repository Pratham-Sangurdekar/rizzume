import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../../core/app_colors.dart';
import '../chat/p2p_chat_screen.dart';

class UserProfileViewScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onBack;

  const UserProfileViewScreen({
    super.key, 
    required this.userId,
    this.onBack,
  });

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _userPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      print('🔍 Loading user profile for userId: ${widget.userId}');
      
      // Fetch user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      print('📄 User doc exists: ${userDoc.exists}');
      print('📄 User data: ${userDoc.data()}');

      // Fetch user's posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .get();

      print('📝 Found ${postsSnapshot.docs.length} posts');

      // Sort posts locally by createdAt
      final posts = postsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      
      posts.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime); // Descending order
      });

      setState(() {
        _userData = userDoc.data();
        _userPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: const Center(
          child: Text(
            'User not found',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    final userName = _userData!['name'] ?? _userData!['userName'] ?? 'User';
    final profilePicture = _userData!['profilePicture'] as String?;
    
    // Try to get bio from multiple possible locations
    String bio = _userData!['bio'] as String? ?? '';
    if (bio.isEmpty) {
      final personalProfile = _userData!['personalProfile'] as Map<String, dynamic>?;
      bio = personalProfile?['bio'] as String? ?? '';
    }
    if (bio.isEmpty) {
      final jobProfile = _userData!['jobProfile'] as Map<String, dynamic>?;
      final experience = jobProfile?['experience'] as Map<String, dynamic>?;
      bio = experience?['description'] as String? ?? '';
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Profile header - Horizontal layout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile picture and info side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile picture (left)
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: AppColors.accent.withOpacity(0.3),
                      backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                          ? MemoryImage(base64Decode(profilePicture))
                          : null,
                      child: profilePicture == null || profilePicture.isEmpty
                          ? Text(
                              userName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    
                    // Username and bio (right)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          
                          if (bio.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              bio,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Posts', _userPosts.length.toString()),
                    _buildStatItem('Followers', '0'),
                    _buildStatItem('Following', '0'),
                  ],
                ),
                
                // Follow and Message buttons (only show for other users)
                if (FirebaseAuth.instance.currentUser?.uid != widget.userId) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement follow functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Follow feature coming soon!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Follow',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Navigate to P2P chat
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => P2PChatScreen(
                                  targetUserId: widget.userId,
                                  targetUserName: _userData?['name'] ?? 
                                                 _userData?['userName'] ?? 
                                                 'User',
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Message',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const Divider(color: Colors.white12),
          
          // Posts grid
          Expanded(
            child: _userPosts.isEmpty
                ? Center(
                    child: Text(
                      'No posts yet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(2),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: _userPosts.length,
                    itemBuilder: (context, index) {
                      final post = _userPosts[index];
                      final imageUrl = post['imageUrl'] as String?;
                      final videoUrl = post['videoUrl'] as String?;
                      final thumbnailUrl = post['thumbnailUrl'] as String?;

                      return Container(
                        color: Colors.white.withOpacity(0.05),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              Image.network(
                                imageUrl.startsWith('data:') || imageUrl.startsWith('http')
                                    ? imageUrl
                                    : 'data:image/jpeg;base64,$imageUrl',
                                fit: BoxFit.cover,
                                errorBuilder: (context, e, st) => const Icon(
                                  Icons.broken_image,
                                  color: Colors.white24,
                                ),
                              )
                            else if (videoUrl != null && videoUrl.isNotEmpty)
                              Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (thumbnailUrl != null)
                                    Image.network(
                                      thumbnailUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, e, st) => const Icon(
                                        Icons.videocam,
                                        color: Colors.white24,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.videocam,
                                      color: Colors.white24,
                                    ),
                                  const Center(
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Center(
                                child: Text(
                                  post['content'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

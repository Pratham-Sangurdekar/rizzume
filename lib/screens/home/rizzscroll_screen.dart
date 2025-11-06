import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import '../../core/app_colors.dart';
import '../../services/firebase_firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class RizzScrollScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final Function(String)? onProfileTap;
  
  const RizzScrollScreen({
    super.key, 
    this.onBackPressed,
    this.onProfileTap,
  });

  @override
  State<RizzScrollScreen> createState() => _RizzScrollScreenState();
}

class _RizzScrollScreenState extends State<RizzScrollScreen> with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  final List<GlobalKey<_RizzScrollVideoPlayerState>> _videoKeys = [];
  List<Map<String, dynamic>> _videos = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => false; // Don't keep alive to allow proper cleanup

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void deactivate() {
    // Pause all videos when leaving the page
    _pauseAllVideos();
    super.deactivate();
  }

  void _pauseAllVideos() {
    for (var key in _videoKeys) {
      key.currentState?.pauseVideo();
    }
  }

  Future<void> _loadVideos() async {
    try {
      // Fetch all recent posts
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      print('📊 Total posts fetched: ${snapshot.docs.length}');

      // Filter for posts with videos
      final videoPosts = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final hasVideo = data['videoUrl'] != null && 
                           data['videoUrl'].toString().isNotEmpty;
            if (hasVideo) {
              print('✅ Found video post: ${doc.id}');
            }
            return hasVideo;
          })
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      setState(() {
        _videos = videoPosts;
        _isLoading = false;
      });
      
      print('📹 RizzScroll loaded ${_videos.length} videos');
    } catch (e) {
      print('❌ Error loading videos: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.neonRed),
        ),
      );
    }

    if (_videos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No RizzScrolls yet',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to post a video!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          final video = _videos[index];
          
          // Create or reuse key for this video
          if (_videoKeys.length <= index) {
            _videoKeys.add(GlobalKey<_RizzScrollVideoPlayerState>());
          }
          
          return RizzScrollVideoPlayer(
            key: _videoKeys[index],
            videoData: video,
            isActive: index == _currentIndex,
            onBackPressed: widget.onBackPressed,
            onProfileTap: widget.onProfileTap,
          );
        },
      ),
    );
  }
}

class RizzScrollVideoPlayer extends StatefulWidget {
  final Map<String, dynamic> videoData;
  final bool isActive;
  final VoidCallback? onBackPressed;
  final Function(String)? onProfileTap;

  const RizzScrollVideoPlayer({
    super.key,
    required this.videoData,
    required this.isActive,
    this.onBackPressed,
    this.onProfileTap,
  });

  @override
  State<RizzScrollVideoPlayer> createState() => _RizzScrollVideoPlayerState();
}

class _RizzScrollVideoPlayerState extends State<RizzScrollVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _liked = false;
  int _likeCount = 0;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    final likedByList = List<String>.from(widget.videoData['likedBy'] ?? []);
    _likeCount = likedByList.length;
    _liked = likedByList.contains(FirebaseAuth.instance.currentUser?.uid ?? '');
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final videoUrl = widget.videoData['videoUrl'] as String?;
    if (videoUrl == null) return;

    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    try {
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.setVolume(1.0);
      setState(() => _initialized = true);

      if (widget.isActive && mounted) {
        _controller.play();
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void didUpdateWidget(RizzScrollVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (_initialized) {
        if (widget.isActive) {
          _controller.play();
        } else {
          _controller.pause();
        }
      }
    }
  }

  void _togglePlayPause() {
    if (_initialized) {
      setState(() {
        if (_controller.value.isPlaying) {
          _controller.pause();
        } else {
          _controller.play();
        }
      });
    }
  }

  // Public method to pause video (called from parent)
  void pauseVideo() {
    if (_initialized && _controller.value.isPlaying) {
      _controller.pause();
    }
  }

  void _toggleLike() async {
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });

    try {
      final postId = widget.videoData['id'] as String;
      await _firestoreService.toggleLike(postId);
    } catch (e) {
      print('Error updating like: $e');
      // Revert on error
      setState(() {
        _liked = !_liked;
        _likeCount += _liked ? 1 : -1;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.videoData['userName'] as String? ?? 'User';
    final content = widget.videoData['content'] as String? ?? '';
    final thumbnailUrl = widget.videoData['thumbnailUrl'] as String?;
    final commentCount = widget.videoData['comments'] ?? 0;
    final profilePicture = widget.videoData['profilePicture'] as String?;
    final userId = widget.videoData['userId'] as String?;

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video or thumbnail
          if (_initialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          else if (thumbnailUrl != null)
            Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Gradient overlay for text readability
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top bar with back button and title (sticky/fixed position)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          if (widget.onBackPressed != null) {
                            widget.onBackPressed!();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'RizzScroll',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right side action buttons
          Positioned(
            right: 12,
            bottom: 24,
            child: Column(
              children: [
                // Like button
                _buildActionButton(
                  icon: _liked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  label: _formatCount(_likeCount),
                  onTap: _toggleLike,
                  color: _liked ? const Color.fromARGB(255, 255, 0, 170) : Colors.white,
                ),
                const SizedBox(height: 12),

                // Comment button
                _buildActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: _formatCount(commentCount),
                  onTap: () {
                    // TODO: Open comments
                  },
                ),
                const SizedBox(height: 12),

                // Share button
                _buildActionButton(
                  icon: Icons.send_rounded,
                  label: '1.2k',
                  onTap: () {
                    // TODO: Share functionality
                  },
                ),
                const SizedBox(height: 12),

                // Save/Bookmark button
                _buildActionButton(
                  icon: Icons.bookmark_border_rounded,
                  label: '',
                  onTap: () {
                    // TODO: Save functionality
                  },
                ),
              ],
            ),
          ),

          // Bottom user info and caption
          Positioned(
            left: 16,
            right: 80,
            bottom: 24,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Username
                  Row(
                    children: [
                      // Profile picture
                      GestureDetector(
                        onTap: () {
                          if (userId != null && widget.onProfileTap != null) {
                            widget.onProfileTap!(userId);
                          }
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                              ? MemoryImage(base64Decode(profilePicture))
                              : null,
                          child: profilePicture == null || profilePicture.isEmpty
                              ? Text(
                                  userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            if (userId != null && widget.onProfileTap != null) {
                              widget.onProfileTap!(userId);
                            }
                          },
                          child: Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Follow',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Play/Pause indicator
          if (!_initialized || !_controller.value.isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _initialized && !_controller.value.isPlaying
                      ? Icons.play_arrow
                      : Icons.refresh,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    // Get screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth > 400 ? 28.0 : 26.0;
    final fontSize = screenWidth > 400 ? 13.0 : 12.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

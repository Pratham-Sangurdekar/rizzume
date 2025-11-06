import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:math';
import '../../core/app_colors.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/floating_deck.dart';
import '../../widgets/feed_video_player.dart';
import '../../widgets/linkable_text.dart';
import '../../widgets/webview_overlay.dart';
// home_tab.dart not used directly; feed is integrated into this file
import 'chats_tab.dart';
import 'jobs_tab.dart';
import 'rizzscroll_screen.dart';
import 'search_tab.dart';
import 'profile_tab_new.dart';
import 'comments_screen.dart';

class HomePlaceholder extends StatefulWidget {
  const HomePlaceholder({super.key});

  @override
  State<HomePlaceholder> createState() => _HomePlaceholderState();
}

class _HomePlaceholderState extends State<HomePlaceholder> {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<SearchTabState> _searchTabKey = GlobalKey<SearchTabState>();

  int _currentIndex = 0;
  bool _isSettingsOpen = false;

  // Randomized neon colors for dopamine effect
  final List<Color> _neonColors = [
    const Color(0xFFDA3BFF), // Magenta
    const Color(0xFF00D9FF), // Cyan
    const Color(0xFF00FF88), // Lime
    const Color(0xFFFFD700), // Gold
    const Color(0xFFFF1493), // Deep Pink
    const Color(0xFF00FFFF), // Aqua
    const Color(0xFF9B4CFF), // Purple
  ];

  Color _getRandomNeonColor() {
    return _neonColors[Random().nextInt(_neonColors.length)];
  }

  void _createPost() {
    Navigator.pushNamed(context, AppRoutes.createPost);
  }

  void _navigateToUserProfile(String userId) {
    setState(() => _currentIndex = 4); // Navigate to search tab (index 4)
    Future.microtask(() {
      _searchTabKey.currentState?.showUserProfile(userId);
    });
  }

  @override
  void initState() {
    super.initState();
  }

  // Get header based on current tab
  PreferredSizeWidget? _getAppBar() {
    final titles = ['Rizzume', 'Messages', '', 'RizzScroll', 'Search', 'Profile'];
    final title = titles[_currentIndex];

    // Jobs tab and RizzScroll have their own headers in the tab content
    if (_currentIndex == 2 || _currentIndex == 3) return null;

    return AppBar(
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: _currentIndex == 0 ? 24 : 22,
          fontWeight: _currentIndex == 0 ? FontWeight.w700 : FontWeight.w600,
          shadows: _currentIndex == 0
              ? [
                  Shadow(
                    color: _neonColors[0].withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
      ),
      actions: [
        // Only show create post button on home tab
        if (_currentIndex == 0) ...[
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: _createPost,
            tooltip: 'Create Post',
          ),
          const SizedBox(width: 12),
        ],

        // Show settings button on profile tab
        if (_currentIndex == 5)
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              setState(() => _isSettingsOpen = true);
              await Navigator.pushNamed(context, AppRoutes.settings);
              setState(() => _isSettingsOpen = false);
            },
            tooltip: 'Settings',
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: _getAppBar(),
      body: Stack(
        children: [
          // Use IndexedStack to preserve state of all pages
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                // Home feed
                StreamBuilder<QuerySnapshot>(
                    stream: _firestoreService.getPosts(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading posts',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: _neonColors[0]),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.post_add, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'No posts yet.\nBe the first to share!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return MediaQuery.removePadding(
                        context: context,
                        removeLeft: true,
                        removeRight: true,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final post = snapshot.data!.docs[index];
                            final postData = post.data() as Map<String, dynamic>;
                            final accentColor = _getRandomNeonColor();

                            final likedByList = List<String>.from(postData['likedBy'] ?? []);
                            
                            return _PostCard(
                              postId: post.id,
                              userId: postData['userId'] ?? '',
                              userName: postData['userName'] ?? 'Anonymous',
                              profilePicture: postData['profilePicture'],
                              content: postData['content'] ?? '',
                              imageUrl: postData['imageUrl'],
                              videoUrl: postData['videoUrl'],
                              thumbnailUrl: postData['thumbnailUrl'],
                              likes: likedByList.length,
                              likedBy: likedByList,
                              commentsCount: postData['comments'] ?? 0,
                              accentColor: accentColor,
                              onLike: () => _firestoreService.toggleLike(post.id),
                              onProfileTap: _navigateToUserProfile,
                            );
                          },
                        ),
                      );
                    },
                  ),
                // Other pages
                const ChatsTab(),
                RizzScrollScreen(
                  onBackPressed: () => setState(() => _currentIndex = 0),
                  onProfileTap: _navigateToUserProfile,
                ),
                JobsTab(),
                SearchTab(key: _searchTabKey),
                const ProfileTabNew(),
              ],
            ),
          ),

          // floating deck is drawn on top (hidden when settings is open OR on RizzScroll page)
          if (!_isSettingsOpen && _currentIndex != 2) 
            FloatingDeck(
              currentIndex: _currentIndex, 
              onTabSelected: (i) => setState(() => _currentIndex = i)
            ),
        ],
      ),
      floatingActionButton: null,
    );
  }
}

class _PostCard extends StatelessWidget {
  final String postId;
  final String userId;
  final String userName;
  final String? profilePicture;
  final String content;
  final String? imageUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int likes;
  final List<String> likedBy;
  final int commentsCount;
  final Color accentColor;
  final VoidCallback onLike;
  final Function(String) onProfileTap;

  const _PostCard({
    required this.postId,
    required this.userId,
    required this.userName,
    this.profilePicture,
    required this.content,
    this.imageUrl,
    this.videoUrl,
    this.thumbnailUrl,
    required this.likes,
    required this.likedBy,
    required this.commentsCount,
    required this.accentColor,
    required this.onLike,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().currentUser?.uid;
    final isLiked = currentUserId != null && likedBy.contains(currentUserId);

    // Instagram-style post: full width, no boxes
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: profile pic + name + menu (with padding)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => onProfileTap(userId),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: accentColor.withValues(alpha: 0.3),
                    backgroundImage: profilePicture != null && profilePicture!.isNotEmpty
                        ? MemoryImage(base64Decode(profilePicture!))
                        : null,
                    child: profilePicture == null || profilePicture!.isEmpty
                        ? Text(
                            userName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onProfileTap(userId),
                    child: Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.7), size: 20),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete post?'),
                          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await FirestoreService().deletePost(postId);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  },
                  itemBuilder: (context) {
                    final currentUserId = AuthService().currentUser?.uid;
                    final isOwner = currentUserId != null && currentUserId == userId;
                    return [
                      if (isOwner) const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      const PopupMenuItem(value: 'report', child: Text('Report')),
                    ];
                  },
                ),
              ],
            ),
          ),

          // Media first (full width, no padding) - Instagram style
          if (videoUrl != null && videoUrl!.isNotEmpty)
            FeedVideoPlayer(
              videoUrl: videoUrl!,
              thumbnailUrl: thumbnailUrl ?? '',
            )
          else if (imageUrl != null && imageUrl!.isNotEmpty)
            Image.network(
              imageUrl!.startsWith('data:') || imageUrl!.startsWith('http')
                  ? imageUrl!
                  : 'data:image/jpeg;base64,$imageUrl',
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, e, st) => imageUrl!.startsWith('data:') || imageUrl!.startsWith('http')
                  ? Container(
                      height: 200,
                      color: Colors.white.withValues(alpha: 0.03),
                      child: Icon(Icons.broken_image, color: Colors.white.withValues(alpha: 0.5)),
                    )
                  : Image.memory(
                      base64Decode(imageUrl!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, e2, st2) => Container(
                        height: 200,
                        color: Colors.white.withValues(alpha: 0.03),
                        child: Icon(Icons.broken_image, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
            ),

          // Content text BEFORE action buttons (for text-only posts)
          if (content.isNotEmpty && imageUrl == null && videoUrl == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: LinkableText(
                text: content,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 14,
                  height: 1.5,
                ),
                onLinkTap: (url) {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false,
                      barrierDismissible: true,
                      barrierColor: Colors.transparent,
                      pageBuilder: (context, _, __) => WebViewOverlay(url: url),
                    ),
                  );
                },
              ),
            ),

          // Action buttons (with padding)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Like button with count
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        color: isLiked ? const Color.fromARGB(255, 255, 17, 0) : Colors.white,
                        size: 25,
                      ),
                      if (likes > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '$likes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Comment button with count
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CommentsScreen(postId: postId)),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mode_comment_outlined,
                        color: Colors.white,
                        size: 25,
                      ),
                      if (commentsCount > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '$commentsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Share button
                GestureDetector(
                  onTap: () {
                    // TODO: Share functionality
                  },
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const Spacer(),

                // Save/Bookmark button
                GestureDetector(
                  onTap: () {
                    // TODO: Save functionality
                  },
                  child: const Icon(
                    Icons.bookmark_border_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ],
            ),
          ),

          // Caption text (for posts with media)
          if (content.isNotEmpty && (imageUrl != null || videoUrl != null))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: LinkableText(
                text: content,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 14,
                  height: 1.4,
                ),
                onLinkTap: (url) {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false,
                      barrierDismissible: true,
                      barrierColor: Colors.transparent,
                      pageBuilder: (context, _, __) => WebViewOverlay(url: url),
                    ),
                  );
                },
              ),
            ),

          // View comments (if any)
          if (commentsCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CommentsScreen(postId: postId)),
                  );
                },
                child: Text(
                  'View all $commentsCount ${commentsCount == 1 ? 'comment' : 'comments'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          // Time ago
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              '1h ago',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


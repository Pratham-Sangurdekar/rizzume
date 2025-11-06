import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class FeedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final double aspectRatio;

  const FeedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isVisible = false;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.setVolume(1.0);
      setState(() => _initialized = true);
      
      // Auto-play if visible
      if (_isVisible && mounted) {
        _controller.play();
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return; // Check if widget is still mounted
    
    final isVisible = info.visibleFraction > 0.5;
    if (_isVisible != isVisible) {
      setState(() => _isVisible = isVisible);
      
      if (_initialized) {
        if (isVisible) {
          _controller.play();
        } else {
          _controller.pause();
        }
      }
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video_${widget.videoUrl}'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: GestureDetector(
        onTap: () {
          setState(() => _showControls = !_showControls);
          _togglePlayPause();
        },
        child: AspectRatio(
          aspectRatio: 9 / 16, // Instagram Reels aspect ratio
          child: Container(
            width: double.infinity,
            color: Colors.black,
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
                else if (widget.thumbnailUrl != null)
                  Image.network(
                    widget.thumbnailUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                // Play/Pause overlay
                if (_showControls && _initialized)
                  Container(
                    color: Colors.black26,
                    child: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),

                // Loading indicator
                if (!_initialized)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

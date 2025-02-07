import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'dart:async';

class VideoPlayerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> videos;
  final int initialIndex;

  const VideoPlayerScreen({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late PageController _pageController;
  final List<CachedVideoPlayerPlusController?> _controllers = List.filled(3, null);
  int _currentIndex = 0;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    // Load current video
    await _loadController(1, widget.videos[_currentIndex]);
    
    // Load next video if available
    if (_currentIndex + 1 < widget.videos.length) {
      await _loadController(2, widget.videos[_currentIndex + 1]);
    }
    
    // Load previous video if available
    if (_currentIndex > 0) {
      await _loadController(0, widget.videos[_currentIndex - 1]);
    }
  }

  Future<void> _loadController(int position, Map<String, dynamic> video) async {
    if (_controllers[position] != null) {
      await _controllers[position]!.dispose();
    }

    final controller = CachedVideoPlayerPlusController.networkUrl(
      Uri.parse(video['video_url'] as String),
      invalidateCacheIfOlderThan: const Duration(days: 1), // Cache for 1 day
    );
    _controllers[position] = controller;

    try {
      await controller.initialize();
      if (position == 1) { // Current video
        controller.play();
        _startHideTimer();
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _onPageChanged(int index) async {
    if (index == _currentIndex) return;

    // Determine scroll direction
    final isForward = index > _currentIndex;
    _currentIndex = index;

    // Pause all videos
    for (final controller in _controllers) {
      controller?.pause();
    }

    if (isForward) {
      // Move controllers back
      _controllers[0]?.dispose();
      _controllers[0] = _controllers[1];
      _controllers[1] = _controllers[2];
      _controllers[2] = null;

      // Load next video if available
      if (_currentIndex + 1 < widget.videos.length) {
        await _loadController(2, widget.videos[_currentIndex + 1]);
      }
    } else {
      // Move controllers forward
      _controllers[2]?.dispose();
      _controllers[2] = _controllers[1];
      _controllers[1] = _controllers[0];
      _controllers[0] = null;

      // Load previous video if available
      if (_currentIndex > 0) {
        await _loadController(0, widget.videos[_currentIndex - 1]);
      }
    }

    // Play current video
    _controllers[1]?.play();
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    for (final controller in _controllers) {
      controller?.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: AppBar(
            backgroundColor: Colors.black26,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: widget.videos.length,
        itemBuilder: (context, index) {
          if (index < _currentIndex - 1 || index > _currentIndex + 1) {
            return const ColoredBox(color: Colors.black);
          }

          final controllerIndex = index - _currentIndex + 1;
          final controller = _controllers[controllerIndex];

          if (controller == null || !controller.value.isInitialized) {
            return Stack(
              children: [
                if (index == _currentIndex)
                  Image.network(
                    widget.videos[index]['thumbnail_url'] as String,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                const Center(child: CircularProgressIndicator()),
              ],
            );
          }

          return _VideoPlayerWidget(
            controller: controller,
            showControls: _showControls,
            title: widget.videos[index]['title'] as String? ?? '',
            onTap: () {
              setState(() {
                _showControls = true;
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
              _startHideTimer();
            },
          );
        },
      ),
    );
  }
}

class _VideoPlayerWidget extends StatelessWidget {
  final CachedVideoPlayerPlusController controller;
  final bool showControls;
  final VoidCallback onTap;
  final String title;

  const _VideoPlayerWidget({
    required this.controller,
    required this.showControls,
    required this.onTap,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CachedVideoPlayerPlus(controller),
          if (showControls)
            Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 64.0,
                color: Colors.white,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
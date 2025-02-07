import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:mikmok/services/video_generation_service.dart';

class VideoResultScreen extends StatefulWidget {
  final String taskId;
  const VideoResultScreen({super.key, required this.taskId});

  @override
  State<VideoResultScreen> createState() => _VideoResultScreenState();
}

class _VideoResultScreenState extends State<VideoResultScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Wait for the video URL from the task
      final videoService = VideoGenerationService();
      final videoUrl = await videoService.waitForVideo(widget.taskId);
      
      print('Attempting to load video from URL: $videoUrl'); // Debug print

      // Initialize video player with the URL
      _controller = VideoPlayerController.network(
        videoUrl,
        httpHeaders: {
          'accept': 'application/json',
          // Add any necessary headers
        },
      )..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            _controller?.play();
            _controller?.setLooping(true);
          }
        }).catchError((error) {
          print('Video initialization error: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error initializing video: $error')),
            );
          }
        });
    } catch (e) {
      print('Error in _initializeVideo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Video'),
      ),
      body: Column(
        children: [
          if (_isInitialized && _controller != null)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller!),
                  _PlayPauseOverlay(controller: _controller!),
                ],
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(),
            ),
          const SizedBox(height: 16),
          if (_controller != null)
            _VideoProgressIndicator(controller: _controller!),
          if (_controller != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    onPressed: () {
                      final newPosition = _controller!.value.position - const Duration(seconds: 10);
                      _controller!.seekTo(newPosition);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller!.value.isPlaying
                            ? _controller!.pause()
                            : _controller!.play();
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    onPressed: () {
                      final newPosition = _controller!.value.position + const Duration(seconds: 10);
                      _controller!.seekTo(newPosition);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayPauseOverlay extends StatelessWidget {
  final VideoPlayerController controller;

  const _PlayPauseOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (!value.isPlaying) {
          return GestureDetector(
            onTap: () {
              controller.play();
            },
            child: Container(
              color: Colors.black26,
              child: const Center(
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 100.0,
                ),
              ),
            ),
          );
        } else {
          return GestureDetector(
            onTap: () {
              controller.pause();
            },
            child: const SizedBox.shrink(),
          );
        }
      },
    );
  }
}

class _VideoProgressIndicator extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoProgressIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final position = value.position;
        final duration = value.duration;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
} 
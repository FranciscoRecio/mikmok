import 'package:flutter/material.dart';
import 'dart:math';

class VideoResultScreen extends StatelessWidget {
  const VideoResultScreen({super.key});

  String _getRandomVideo() {
    // List of sample video URLs (you can replace these with your actual videos)
    final videos = [
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      // Add more video URLs as needed
    ];
    
    final random = Random();
    return videos[random.nextInt(videos.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Video'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Video player coming soon...',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Random Video URL:\n${_getRandomVideo()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
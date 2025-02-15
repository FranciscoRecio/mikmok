import 'package:flutter/material.dart';
import '../models/scene.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/video_generation_service.dart';
import '../screens/video_result_screen.dart';
import '../models/persona.dart';

class ScenePromptScreen extends StatefulWidget {
  final Scene? startScene;
  final Scene? endScene;
  final Persona? persona;

  const ScenePromptScreen({
    super.key,
    this.startScene,
    this.endScene,
    this.persona,
  });

  @override
  State<ScenePromptScreen> createState() => _ScenePromptScreenState();
}

class _ScenePromptScreenState extends State<ScenePromptScreen> {
  final _promptController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Video'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Scenes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      if (widget.startScene != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.startScene!.imageUrl,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start: ${widget.startScene!.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ] else
                        const Text('No start scene selected'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      if (widget.endScene != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.endScene!.imageUrl,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'End: ${widget.endScene!.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ] else
                        const Text('No end scene selected'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Enter Prompt',
                hintText: 'Describe how the scene should transition...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleGenerate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Generate',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGenerate() async {
    if (_promptController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final videoService = VideoGenerationService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final taskId = await videoService.generateVideo(
        prompt: _promptController.text,
        userId: userId,
        startImageUrl: widget.startScene?.imageUrl,
        endImageUrl: widget.endScene?.imageUrl,
        personaUrl: widget.persona?.imageUrl,
      );

      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VideoResultScreen(taskId: taskId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 
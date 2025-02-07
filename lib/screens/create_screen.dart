import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mikmok/providers/auth_provider.dart';
import 'package:mikmok/providers/avatar_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mikmok/services/video_generation_service.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  final _contextController = TextEditingController();
  final _scriptController = TextEditingController();
  String? _selectedAvatarId;
  Map<String, List<int>> _avatarImageBytes = {}; // Store image bytes by avatar ID

  @override
  void dispose() {
    _promptController.dispose();
    _contextController.dispose();
    _scriptController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating video...')),
        );

        final userId = Provider.of<AuthProvider>(context, listen: false).user!.uid;
        
        // Get avatar once
        final avatars = await Provider.of<AvatarProvider>(context, listen: false)
            .getUserAvatars(userId)
            .first;

        if (_selectedAvatarId == null) {
          throw Exception('Please select an avatar');
        }

        // Use cached image bytes
        final imageBytes = _avatarImageBytes[_selectedAvatarId];
        if (imageBytes == null) {
          throw Exception('Avatar image not loaded');
        }

        final videoService = VideoGenerationService();
        final taskId = await videoService.generateVideo(
          _promptController.text,
          imageBytes,
          userId,
        );

        if (!mounted) return;

        // Navigate to video result screen with task ID
        context.push('/video-result', extra: taskId);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Add this method to load and cache image bytes
  Future<void> _loadAvatarImage(String avatarId, String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        setState(() {
          _avatarImageBytes[avatarId] = response.bodyBytes;
        });
      }
    } catch (e) {
      print('Error loading avatar image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthProvider>(context).user?.uid;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    StreamBuilder(
                      stream: Provider.of<AvatarProvider>(context).getUserAvatars(userId ?? ''),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final avatars = snapshot.data!;
                        // Set initial value to most recent avatar if not already selected
                        if (_selectedAvatarId == null && avatars.isNotEmpty) {
                          _selectedAvatarId = avatars.first.id;
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Select Avatar',
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedAvatarId,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('No Avatar'),
                                  ),
                                  ...avatars.map((avatar) => DropdownMenuItem(
                                    value: avatar.id,
                                    child: Text(avatar.name),
                                  )),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedAvatarId = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (_selectedAvatarId != null)
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: FutureBuilder(
                                  future: _loadAvatarImage(_selectedAvatarId!, avatars.firstWhere((a) => a.id == _selectedAvatarId).imageUrl),
                                  builder: (context, snapshot) {
                                    if (_avatarImageBytes.containsKey(_selectedAvatarId)) {
                                      return SvgPicture.memory(
                                        Uint8List.fromList(_avatarImageBytes[_selectedAvatarId]!),
                                        placeholderBuilder: (context) => const CircularProgressIndicator(color: Colors.green),
                                      );
                                    }
                                    return const CircularProgressIndicator(color: Colors.green);
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _promptController,
                      decoration: const InputDecoration(
                        labelText: 'Prompt *',
                        border: OutlineInputBorder(),
                        hintText: 'Enter your prompt',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a prompt';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _contextController,
                      decoration: const InputDecoration(
                        labelText: 'Context (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'Enter the context',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _scriptController,
                      decoration: const InputDecoration(
                        labelText: 'Script (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'Enter your script',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 10,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '* Required field',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Generate',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
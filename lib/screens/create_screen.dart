import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mikmok/providers/auth_provider.dart';
import 'package:mikmok/providers/avatar_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  @override
  void dispose() {
    _promptController.dispose();
    _contextController.dispose();
    _scriptController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating video...')),
      );
      
      // Navigate to video result screen
      context.push('/video-result');
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
                                child: SvgPicture.network(
                                  avatars.firstWhere((a) => a.id == _selectedAvatarId).imageUrl,
                                  placeholderBuilder: (context) => const CircularProgressIndicator(color: Colors.green),
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
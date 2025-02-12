import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scene_provider.dart';
import '../models/persona.dart';

class CreateSceneScreen extends StatefulWidget {
  final Persona persona;

  const CreateSceneScreen({
    super.key,
    required this.persona,
  });

  @override
  State<CreateSceneScreen> createState() => _CreateSceneScreenState();
}

class _CreateSceneScreenState extends State<CreateSceneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final sceneProvider = Provider.of<SceneProvider>(context, listen: false);
        final taskId = await sceneProvider.startGeneration(
          prompt: _promptController.text,
          userId: widget.persona.userId,
          personaId: widget.persona.id,
          personaUrl: widget.persona.imageUrl,
        );

        if (!mounted) return;

        // Initial delay to let the task start
        await Future.delayed(const Duration(seconds: 2));

        // Poll for status
        bool isComplete = false;
        while (!isComplete && mounted) {
          final status = await sceneProvider.checkGenerationStatus(taskId);
          
          if (status['status'] == 'SUCCESS') {
            isComplete = true;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Scene generated successfully!')),
            );
          } else if (status['status'] == 'FAILURE') {
            throw status['error'] ?? 'Failed to generate scene';
          } else {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Scene'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.persona.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error_outline);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.persona.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: 'Action Prompt',
                  hintText: 'Describe what you want to do in this scene... e.g. Running in a park',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a prompt';
                  }
                  return null;
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Generate Scene',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
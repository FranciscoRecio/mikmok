import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scene_provider.dart';
import '../models/persona.dart';
import '../models/scene.dart';

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
  bool _extendScene = false;
  String? _selectedSceneId;
  String? _selectedSceneUrl;

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
        
        final taskId = _extendScene && _selectedSceneId != null
            ? await sceneProvider.startSceneToSceneGeneration(
                prompt: _promptController.text,
                userId: widget.persona.userId,
                personaId: widget.persona.id,
                sceneUrl: _selectedSceneUrl!,
              )
            : await sceneProvider.startGeneration(
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
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Extend an existing scene'),
                subtitle: const Text('Generate the final scene from the selected scene'),
                value: _extendScene,
                onChanged: (bool value) {
                  setState(() {
                    _extendScene = value;
                    if (!value) {
                      _selectedSceneId = null;
                      _selectedSceneUrl = null;
                    }
                  });
                },
              ),
              if (_extendScene) ...[
                const SizedBox(height: 16),
                StreamBuilder<List<Scene>>(
                  stream: Provider.of<SceneProvider>(context)
                      .getUserScenesForPersona(widget.persona.userId, widget.persona.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final scenes = snapshot.data ?? [];

                    if (scenes.isEmpty) {
                      return const Text('No scenes available to extend');
                    }

                    return Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: scenes.length,
                        itemBuilder: (context, index) {
                          final scene = scenes[index];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSceneId = scene.id;
                                _selectedSceneUrl = scene.imageUrl;
                              });
                            },
                            child: Card(
                              color: _selectedSceneId == scene.id 
                                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: Image.network(
                                        scene.imageUrl,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.error_outline, size: 40);
                                        },
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      scene.name,
                                      style: Theme.of(context).textTheme.titleMedium,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading || (_extendScene && _selectedSceneId == null)
                      ? null 
                      : _handleSubmit,
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
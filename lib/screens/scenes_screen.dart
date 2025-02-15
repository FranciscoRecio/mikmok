import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/persona_provider.dart';
import '../providers/scene_provider.dart';
import '../models/persona.dart';
import '../models/scene.dart';
import '../providers/avatar_provider.dart';
import '../models/avatar.dart';
import '../screens/create_scene_screen.dart';
import '../screens/scene_prompt_screen.dart';
import '../screens/scene_detail_screen.dart';
import '../providers/settings_provider.dart';

class ScenesScreen extends StatefulWidget {
  const ScenesScreen({super.key});

  @override
  State<ScenesScreen> createState() => _ScenesScreenState();
}

class _ScenesScreenState extends State<ScenesScreen> {
  Persona? selectedPersona;
  Scene? selectedStartScene;
  Scene? selectedEndScene;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Center(child: Text('Please log in to view scenes'));
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Thumbnails',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPersonaDropdown(userId),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: selectedPersona == null ? null : () async {
                              final personas = await Provider.of<PersonaProvider>(context, listen: false)
                                  .getUserPersonas(
                                    userId,
                                    isVirtual: Provider.of<SettingsProvider>(context, listen: false).isVirtual,
                                  )
                                  .first;
                              
                              final taskId = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateSceneScreen(
                                    persona: selectedPersona!,
                                  ),
                                ),
                              );

                              if (taskId != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Started generating new scene...'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add),
                                SizedBox(width: 8),
                                Text(
                                  'Add New Thumbnail',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: StreamBuilder<List<Scene>>(
                    stream: Provider.of<SceneProvider>(context)
                        .getUserScenesForPersona(userId, selectedPersona?.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return SliverToBoxAdapter(
                          child: Center(child: Text('Error: ${snapshot.error}')),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final scenes = snapshot.data ?? [];

                      if (scenes.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32.0),
                              child: Text(
                                'No scenes yet for this persona.\nCreate one to get started!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildSceneCard(scenes[index]),
                          childCount: scenes.length,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (selectedPersona != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: StreamBuilder<List<Scene>>(
                stream: Provider.of<SceneProvider>(context)
                    .getUserScenesForPersona(userId, selectedPersona!.id),
                builder: (context, snapshot) {
                  final scenes = snapshot.data ?? [];
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('None'),
                                ),
                                ...scenes.map((scene) {
                                  return DropdownMenuItem<String?>(
                                    value: scene.id,
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 120),
                                      child: Text(
                                        scene.name,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Start Frame',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              value: selectedStartScene?.id,
                              onChanged: (value) {
                                setState(() {
                                  selectedStartScene = value != null 
                                      ? scenes.firstWhere((s) => s.id == value)
                                      : null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('None'),
                                ),
                                ...scenes.map((scene) {
                                  return DropdownMenuItem<String?>(
                                    value: scene.id,
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 100),
                                      child: Text(
                                        scene.name,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'End Frame',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              value: selectedEndScene?.id,
                              onChanged: (value) {
                                setState(() {
                                  selectedEndScene = value != null 
                                      ? scenes.firstWhere((s) => s.id == value)
                                      : null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScenePromptScreen(
                                  startScene: selectedStartScene,
                                  endScene: selectedEndScene,
                                  persona: selectedPersona,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Generate Video',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonaDropdown(String userId) {
    return StreamBuilder<List<Persona>>(
      stream: Provider.of<PersonaProvider>(context).getUserPersonas(
        userId,
        isVirtual: Provider.of<SettingsProvider>(context).isVirtual,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final personas = snapshot.data ?? [];

        if (personas.isEmpty) {
          return const Text('Create a persona first to generate scenes');
        }

        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                decoration: const InputDecoration(
                  labelText: 'Select Persona',
                  border: OutlineInputBorder(),
                ),
                value: selectedPersona?.id,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('None'),
                  ),
                  ...personas.map((persona) {
                    return DropdownMenuItem(
                      value: persona.id,
                      child: Text(persona.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    if (value != null) {
                      selectedPersona = personas.firstWhere(
                        (p) => p.id == value,
                        orElse: () => personas.first,
                      );
                    } else {
                      selectedPersona = null;
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            if (selectedPersona != null)
              SizedBox(
                width: 60,
                height: 60,
                child: Image.network(
                  selectedPersona!.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error_outline, size: 40);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSceneCard(Scene scene) {
    return Card(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Padding(
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
          Positioned(
            top: 4,
            right: 4,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SceneDetailScreen(scene: scene),
                    ),
                  );
                } else if (value == 'delete') {
                  _showDeleteDialog(context, scene);
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Scene scene) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Scene'),
        content: Text('Are you sure you want to delete ${scene.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await Provider.of<SceneProvider>(context, listen: false)
                    .deleteScene(scene.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scene deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting scene: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 
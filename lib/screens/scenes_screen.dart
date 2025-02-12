import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/persona_provider.dart';
import '../providers/scene_provider.dart';
import '../models/persona.dart';
import '../models/scene.dart';
import '../providers/avatar_provider.dart';
import '../models/avatar.dart';

class ScenesScreen extends StatefulWidget {
  const ScenesScreen({super.key});

  @override
  State<ScenesScreen> createState() => _ScenesScreenState();
}

class _ScenesScreenState extends State<ScenesScreen> {
  String? selectedAvatarId;
  String? selectedPersonaId;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Center(child: Text('Please log in to view scenes'));
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Scenes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAvatarDropdown(userId),
                const SizedBox(height: 16),
                if (selectedAvatarId != null) _buildPersonaDropdown(userId),
              ],
            ),
          ),
        ),
        if (selectedPersonaId != null) ...[
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: StreamBuilder<List<Scene>>(
              stream: Provider.of<SceneProvider>(context)
                  .getUserScenesForPersona(userId, selectedPersonaId!),
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
      ],
    );
  }

  Widget _buildAvatarDropdown(String userId) {
    return StreamBuilder<List<Avatar>>(
      stream: Provider.of<AvatarProvider>(context).getUserAvatars(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final avatars = snapshot.data ?? [];

        if (avatars.isEmpty) {
          return const Text('Create an avatar first to view scenes');
        }

        // Auto-select first avatar if none selected
        if (selectedAvatarId == null && avatars.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              selectedAvatarId = avatars.first.id;
              selectedPersonaId = null; // Reset persona selection
            });
          });
        }

        final selectedAvatar = avatars.firstWhere(
          (avatar) => avatar.id == selectedAvatarId,
          orElse: () => avatars.first,
        );

        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Avatar',
                  border: OutlineInputBorder(),
                ),
                value: selectedAvatarId ?? avatars.first.id,
                items: avatars.map((avatar) {
                  return DropdownMenuItem(
                    value: avatar.id,
                    child: Text(avatar.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAvatarId = value;
                    selectedPersonaId = null; // Reset persona selection when avatar changes
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
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
                  selectedAvatar.imageUrl,
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
          ],
        );
      },
    );
  }

  Widget _buildPersonaDropdown(String userId) {
    return StreamBuilder<List<Persona>>(
      stream: Provider.of<PersonaProvider>(context)
          .getUserPersonasForAvatar(userId, selectedAvatarId!),
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

        // Auto-select first persona if none selected
        if (selectedPersonaId == null && personas.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              selectedPersonaId = personas.first.id;
            });
          });
        }

        final selectedPersona = personas.firstWhere(
          (persona) => persona.id == selectedPersonaId,
          orElse: () => personas.first,
        );

        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Persona',
                  border: OutlineInputBorder(),
                ),
                value: selectedPersonaId ?? personas.first.id,
                items: personas.map((persona) {
                  return DropdownMenuItem(
                    value: persona.id,
                    child: Text(persona.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPersonaId = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
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
                  selectedPersona.imageUrl,
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
          ],
        );
      },
    );
  }

  Widget _buildSceneCard(Scene scene) {
    return Card(
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
    );
  }
} 
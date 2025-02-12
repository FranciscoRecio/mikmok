import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/avatar_provider.dart';
import '../providers/persona_provider.dart';
import '../models/avatar.dart';
import '../models/persona.dart';

class PersonasScreen extends StatefulWidget {
  const PersonasScreen({super.key});

  @override
  State<PersonasScreen> createState() => _PersonasScreenState();
}

class _PersonasScreenState extends State<PersonasScreen> {
  String? selectedAvatarId;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Center(child: Text('Please log in to view personas'));
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
                  'Your Personas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAvatarDropdown(userId),
                ElevatedButton(
                  onPressed: () => context.push('/persona-customization'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('Create New Persona'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (selectedAvatarId != null) ...[
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: StreamBuilder<List<Persona>>(
              stream: Provider.of<PersonaProvider>(context)
                  .getUserPersonasForAvatar(userId, selectedAvatarId!),
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

                final personas = snapshot.data ?? [];

                if (personas.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          'No personas yet for this avatar.\nCreate one to get started!',
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
                    (context, index) => _buildPersonaCard(personas[index]),
                    childCount: personas.length,
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
          return const Text('Create an avatar first to generate personas');
        }

        // Auto-select first avatar if none selected
        if (selectedAvatarId == null && avatars.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              selectedAvatarId = avatars.first.id;
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
                value: selectedAvatarId ?? avatars.first.id,
                decoration: const InputDecoration(
                  labelText: 'Select Avatar',
                  border: OutlineInputBorder(),
                ),
                items: avatars.map((avatar) {
                  return DropdownMenuItem(
                    value: avatar.id,
                    child: Text(avatar.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAvatarId = value;
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
                child: selectedAvatar.imageUrl.isNotEmpty
                    ? Image.network(
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
                      )
                    : const Icon(Icons.account_circle, size: 40, color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPersonaCard(Persona persona) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/persona-customization', extra: persona),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Image.network(
                  persona.imageUrl,
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
                persona.name,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                persona.metadata['prompt'] as String? ?? 'No prompt',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/avatar_provider.dart';
import '../models/avatar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/persona.dart';
import '../screens/avatar_detail_screen.dart';
import '../providers/persona_provider.dart';

class AvatarsScreen extends StatefulWidget {
  const AvatarsScreen({super.key});

  @override
  _AvatarsScreenState createState() => _AvatarsScreenState();
}

class _AvatarsScreenState extends State<AvatarsScreen> {
  Avatar? selectedAvatar;

  void _showNameDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Persona'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter a name for your persona',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(dialogContext);
              
              try {
                final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
                if (userId == null) throw Exception('User not logged in');
                
                final taskId = await Provider.of<PersonaProvider>(context, listen: false)
                    .startGeneration(
                      name: name,
                      userId: userId,
                      avatarId: selectedAvatar!.id,
                      avatarUrl: selectedAvatar!.imageUrl,
                    );
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Persona generation started!')),
                );
                Navigator.pop(context);  // Return to previous screen
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating persona: $e')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Center(child: Text('Please log in to view avatars'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Base Model'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Avatars',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/avatar-customization'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shuffle),
                        SizedBox(width: 8),
                        Text('Generate Random Avatar'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: StreamBuilder<List<Avatar>>(
              stream: Provider.of<AvatarProvider>(context).getUserAvatars(userId),
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

                final avatars = snapshot.data ?? [];

                if (avatars.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          'No avatars yet.\nCreate one to get started!',
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
                    (context, index) => _buildAvatarCard(context, avatars[index], showOptions: true),
                    childCount: avatars.length,
                  ),
                );
              },
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Other Avatars',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: StreamBuilder<List<Avatar>>(
              stream: Provider.of<AvatarProvider>(context).getOtherAvatars(userId),
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

                final otherAvatars = snapshot.data ?? [];

                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildAvatarCard(context, otherAvatars[index], showOptions: false),
                    childCount: otherAvatars.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: selectedAvatar != null
          ? FloatingActionButton.extended(
              onPressed: _showNameDialog,
              icon: const Icon(Icons.add),
              label: const Text('Generate Persona'),
            )
          : null,
    );
  }

  Widget _buildAvatarCard(BuildContext context, Avatar avatar, {bool showOptions = false}) {
    final isSelected = avatar.id == selectedAvatar?.id;
    
    return Card(
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                selectedAvatar = isSelected ? null : avatar;
              });
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.network(
                    avatar.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error_outline, size: 40);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  avatar.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (showOptions)
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AvatarDetailScreen(avatar: avatar),
                      ),
                    );
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, avatar);
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

  void _showDeleteDialog(BuildContext context, Avatar avatar) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Avatar'),
        content: Text('Are you sure you want to delete ${avatar.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await Provider.of<AvatarProvider>(context, listen: false)
                    .deleteAvatar(avatar.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Avatar deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting avatar: $e')),
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
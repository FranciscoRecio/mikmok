import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/avatar_provider.dart';
import '../models/avatar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/persona.dart';
import '../screens/avatar_detail_screen.dart';

class AvatarsScreen extends StatelessWidget {
  const AvatarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Center(child: Text('Please log in to view avatars'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Avatar Model'),
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
                    (context, index) => _buildAvatarCard(context, avatars[index]),
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
                    (context, index) => _buildAvatarCard(context, otherAvatars[index]),
                    childCount: otherAvatars.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(BuildContext context, Avatar avatar) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AvatarDetailScreen(avatar: avatar),
            ),
          );
        },
        onLongPress: () => _showDeleteDialog(context, avatar),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (avatar.imageUrl.isNotEmpty) ...[
              SizedBox(
                width: 80,
                height: 80,
                child: Image.network(
                  avatar.imageUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error_outline, size: 40);
                  },
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ] else
              const Icon(Icons.account_circle, size: 80, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              avatar.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Avatar avatar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Avatar'),
        content: Text('Are you sure you want to delete ${avatar.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
              
              avatarProvider.deleteAvatar(avatar.id);
              Navigator.pop(context);
              
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: const Text('Avatar deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      avatarProvider.undoDelete().then((_) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Avatar restored')),
                        );
                      });
                    },
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 
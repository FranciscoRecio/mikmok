import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/avatar_provider.dart';
import '../models/avatar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AvatarsScreen extends StatefulWidget {
  const AvatarsScreen({super.key});

  @override
  State<AvatarsScreen> createState() => _AvatarsScreenState();
}

class _AvatarsScreenState extends State<AvatarsScreen> {
  String avatarName = '';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Center(child: Text('Please log in to view avatars'));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text('Create New Avatar'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<List<Avatar>>(
              stream: Provider.of<AvatarProvider>(context).getUserAvatars(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Stream error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final avatars = snapshot.data ?? [];

                if (avatars.isEmpty) {
                  return const Center(
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
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: avatars.length,
                  itemBuilder: (context, index) {
                    final avatar = avatars[index];
                    print('Avatar URL: ${avatar.imageUrl}');

                    return Card(
                      child: InkWell(
                        onTap: () {
                          context.push('/avatar-customization', extra: avatar);
                        },
                        onLongPress: () {
                          // Show delete confirmation
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
                                                const SnackBar(
                                                  content: Text('Avatar restored'),
                                                ),
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (avatar.imageUrl.isNotEmpty) ...[
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: SvgPicture.network(
                                  avatar.imageUrl,
                                  placeholderBuilder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                            ] else
                              const Icon(
                                Icons.account_circle,
                                size: 80,
                                color: Colors.grey,
                              ),
                            const SizedBox(height: 8),
                            Text(
                              avatar.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Sample Avatars',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sample_avatars')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sampleAvatars = snapshot.data?.docs ?? [];

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sampleAvatars.length,
                  itemBuilder: (context, index) {
                    final avatar = sampleAvatars[index].data() as Map<String, dynamic>;
                    final imageUrl = avatar['imageUrl'] as String;
                    final name = avatar['name'] as String;

                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Save Avatar'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Would you like to save this avatar?'),
                                const SizedBox(height: 16),
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Avatar Name',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) => avatarName = value,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (userId != null) {
                                    Provider.of<AvatarProvider>(context, listen: false).createAvatar(
                                      userId,
                                      avatarName.isNotEmpty ? avatarName : name,
                                      {'image_url': imageUrl},
                                    );
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Avatar saved!')),
                                    );
                                  }
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: SvgPicture.network(
                                imageUrl,
                                placeholderBuilder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 
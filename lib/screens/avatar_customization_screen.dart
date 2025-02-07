import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/avatar_provider.dart';
import '../models/avatar.dart';
import '../services/avatar_generation_service.dart';
import '../widgets/avatar_generation_loading.dart';

class AvatarCustomizationScreen extends StatefulWidget {
  final Avatar? avatar; // Add this to support editing existing avatars
  const AvatarCustomizationScreen({super.key, this.avatar});

  @override
  State<AvatarCustomizationScreen> createState() => _AvatarCustomizationScreenState();
}

class _AvatarCustomizationScreenState extends State<AvatarCustomizationScreen> {
  String _selectedFeature = 'face';
  Color _selectedColor = Colors.blue;
  final _nameController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.avatar != null) {
      _nameController.text = widget.avatar!.name;
      if (widget.avatar!.customization['color'] != null) {
        _selectedColor = Color(widget.avatar!.customization['color']);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveAvatar() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your avatar')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
      
      if (widget.avatar != null) {
        // Update existing avatar
        await avatarProvider.updateAvatar(
          widget.avatar!.id,
          _nameController.text,
          {'color': _selectedColor.value},
        );
      } else {
        // Create new avatar
        await avatarProvider.createAvatar(
          userId,
          _nameController.text,
          {'color': _selectedColor.value},
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.avatar != null ? 'Avatar updated!' : 'Avatar created!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _generateAvatar() async {
    setState(() => _isLoading = true);
    
    try {
      print('Starting avatar generation...'); // Debug
      final avatarService = AvatarGenerationService();
      
      final taskId = await avatarService.generateAvatar(
        _nameController.text.isEmpty ? 'My Avatar' : _nameController.text,
        {}, // style params
      );
      
      print('Got task ID: $taskId'); // Debug

      if (!mounted) return;

      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AvatarGenerationLoading(
          taskId: taskId,
          onComplete: (imageUrl) {
            Navigator.of(context).pop(imageUrl);
          },
        ),
      );

      if (!mounted) return;
      
      if (result != null) {
        final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
        if (userId == null) {
          throw Exception('User not logged in');
        }

        await Provider.of<AvatarProvider>(context, listen: false).createAvatar(
          userId,
          _nameController.text.isEmpty ? 'My Avatar' : _nameController.text,
          {'imageUrl': result},
        );

        if (!mounted) return;
        
        Navigator.pop(context); // Return to avatars screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar created successfully!')),
        );
      }
    } catch (e) {
      print('Error in avatar generation: $e'); // Debug
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.avatar != null ? 'Edit Avatar' : 'Create Avatar'),
        actions: [
          if (widget.avatar != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Avatar'),
                    content: Text('Are you sure you want to delete ${widget.avatar!.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
                          
                          try {
                            await avatarProvider.deleteAvatar(widget.avatar!.id);
                            if (mounted) {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Return to avatars screen
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
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context); // Close dialog
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text('Error deleting avatar: $e')),
                              );
                            }
                          }
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
            ),
          if (widget.avatar != null)
            TextButton(
              onPressed: _isSaving ? null : _saveAvatar,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Avatar Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.face,
                  size: 120,
                  color: _selectedColor,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customize',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FeatureButton(
                          icon: Icons.face,
                          label: 'Face',
                          isSelected: _selectedFeature == 'face',
                          onTap: () => setState(() => _selectedFeature = 'face'),
                        ),
                        _FeatureButton(
                          icon: Icons.style,
                          label: 'Style',
                          isSelected: _selectedFeature == 'style',
                          onTap: () => setState(() => _selectedFeature = 'style'),
                        ),
                        _FeatureButton(
                          icon: Icons.color_lens,
                          label: 'Color',
                          isSelected: _selectedFeature == 'color',
                          onTap: () => setState(() => _selectedFeature = 'color'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildFeatureOptions(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.avatar == null)
            ElevatedButton(
              onPressed: _isLoading ? null : _generateAvatar,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Generate Avatar'),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureOptions() {
    switch (_selectedFeature) {
      case 'color':
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: Colors.primaries.length,
          itemBuilder: (context, index) {
            final color = Colors.primaries[index];
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: _selectedColor == color
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                ),
              ),
            );
          },
        );
      default:
        return const Center(
          child: Text(
            'More options coming soon...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        );
    }
  }
}

class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeatureButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/avatar.dart';
import '../providers/avatar_provider.dart';

class AvatarDetailScreen extends StatefulWidget {
  final Avatar avatar;

  const AvatarDetailScreen({super.key, required this.avatar});

  @override
  State<AvatarDetailScreen> createState() => _AvatarDetailScreenState();
}

class _AvatarDetailScreenState extends State<AvatarDetailScreen> {
  late TextEditingController _nameController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.avatar.name);
    _nameController.addListener(_checkChanges);
  }

  void _checkChanges() {
    setState(() {
      _hasChanges = _nameController.text != widget.avatar.name;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    try {
      await Provider.of<AvatarProvider>(context, listen: false)
          .updateAvatar(widget.avatar.id, name: _nameController.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating avatar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar Details'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              child: Image.network(
                widget.avatar.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error_outline, size: 64),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _hasChanges ? _saveChanges : null,
                child: const Text('Save Changes'),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
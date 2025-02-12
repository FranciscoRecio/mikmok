import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/avatar_provider.dart';
import '../models/avatar.dart';

class AvatarCustomizationScreen extends StatefulWidget {
  final Avatar? avatar;
  const AvatarCustomizationScreen({super.key, this.avatar});

  @override
  State<AvatarCustomizationScreen> createState() => _AvatarCustomizationScreenState();
}

class _AvatarCustomizationScreenState extends State<AvatarCustomizationScreen> {
  final _textController = TextEditingController();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    if (widget.avatar != null) {
      _textController.text = widget.avatar!.seed;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _generateAvatar() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description for your avatar')),
      );
      return;
    }

    try {
      setState(() => _isGenerating = true);
      
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
      if (userId == null) throw Exception('User not logged in');

      await Provider.of<AvatarProvider>(context, listen: false)
          .generateAvatar(userId, _textController.text);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar generation started!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.avatar != null ? 'Edit Avatar' : 'Create Avatar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Describe your avatar',
                hintText: 'E.g., A happy robot with blue eyes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateAvatar,
              child: _isGenerating
                  ? const CircularProgressIndicator()
                  : const Text('Generate Avatar'),
            ),
          ],
        ),
      ),
    );
  }
} 
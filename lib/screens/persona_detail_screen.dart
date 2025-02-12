import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/persona.dart';
import '../providers/persona_provider.dart';

class PersonaDetailScreen extends StatefulWidget {
  final Persona persona;

  const PersonaDetailScreen({super.key, required this.persona});

  @override
  State<PersonaDetailScreen> createState() => _PersonaDetailScreenState();
}

class _PersonaDetailScreenState extends State<PersonaDetailScreen> {
  late TextEditingController _nameController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.persona.name);
    _nameController.addListener(_checkChanges);
  }

  void _checkChanges() {
    setState(() {
      _hasChanges = _nameController.text != widget.persona.name;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    try {
      await Provider.of<PersonaProvider>(context, listen: false)
          .updatePersona(widget.persona.id, name: _nameController.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Persona updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating persona: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persona Details'),
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
                widget.persona.imageUrl,
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
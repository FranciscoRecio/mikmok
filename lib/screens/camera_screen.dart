import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../providers/persona_provider.dart';
import '../providers/auth_provider.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isLoading = true;
  String? _error;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      setState(() => _imagePath = image.path);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _usePhoto() async {
    if (_imagePath == null) return;

    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
      if (userId == null) throw Exception('User not logged in');
      if (!mounted) return;

      // Show name input dialog first
      final name = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildNameDialog(),
      );

      // If user cancels dialog, name will be null
      if (name == null || !mounted) return;

      // Only show loading after user confirms
      setState(() => _isLoading = true);

      final taskId = await Provider.of<PersonaProvider>(context, listen: false)
          .startPhotoGeneration(
            userId: userId,
            name: name,
            photoPath: _imagePath!,
          );

      if (!mounted) return;
      Navigator.pop(context, taskId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create persona: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _retakePhoto() {
    setState(() => _imagePath = null);
  }

  Widget _buildNameDialog() {
    final controller = TextEditingController();
    return AlertDialog(
      title: const Text('Name your persona'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Enter name',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(context, name);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text('Error: $_error'),
        ),
      );
    }

    if (_isLoading || _controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_imagePath == null) ...[
              Center(
                child: CameraPreview(_controller!),
              ),
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: Image.file(File(_imagePath!)),
              ),
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _retakePhoto,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _usePhoto,
                      icon: const Icon(Icons.check),
                      label: const Text('Use Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Positioned(
              left: 16,
              top: 16,
              child: IconButton(
                icon: const Icon(Icons.close),
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
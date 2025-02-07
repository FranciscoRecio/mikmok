import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/avatar_provider.dart';
import '../services/avatar_generation_service.dart';

class AvatarGenerationLoading extends StatefulWidget {
  final String taskId;
  final Function(String) onComplete;

  const AvatarGenerationLoading({
    super.key,
    required this.taskId,
    required this.onComplete,
  });

  @override
  State<AvatarGenerationLoading> createState() => _AvatarGenerationLoadingState();
}

class _AvatarGenerationLoadingState extends State<AvatarGenerationLoading> {
  bool _hasCompleted = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: AvatarGenerationService().waitForAvatar(widget.taskId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('${snapshot.error}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        }

        if (snapshot.hasData && !_hasCompleted) {
          _hasCompleted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onComplete(snapshot.data!);
          });
          return const SizedBox.shrink();
        }

        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating your avatar...'),
            ],
          ),
        );
      },
    );
  }
} 
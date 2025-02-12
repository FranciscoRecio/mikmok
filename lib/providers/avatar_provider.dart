import 'package:flutter/foundation.dart';
import '../models/avatar.dart';
import '../services/avatar_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvatarProvider extends ChangeNotifier {
  final AvatarService _avatarService = AvatarService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _error;
  Avatar? _lastDeletedAvatar;
  Map<String, dynamic>? _lastDeletedData;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Avatar>> getUserAvatars(String userId) {
    return _avatarService.getUserAvatars(userId);
  }

  Future<void> generateAvatar(String userId, String text) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final taskId = await _avatarService.startGeneration(userId, text);
      await _pollGeneration(taskId);

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _pollGeneration(String taskId) async {
    while (true) {
      try {
        final status = await _avatarService.checkGenerationStatus(taskId);
        
        if (status['status'] == 'COMPLETED') {
          break;
        } else if (status['status'] == 'FAILED') {
          throw 'Avatar generation failed';
        }
        
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        throw 'Error checking generation status: $e';
      }
    }
  }

  Future<void> updateAvatar(String avatarId, String name, Map<String, dynamic> customization) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _avatarService.updateAvatar(avatarId, name, customization);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAvatar(String avatarId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final avatarData = await _avatarService.getAvatar(avatarId);
      if (avatarData != null) {
        _lastDeletedAvatar = Avatar.fromMap(avatarId, avatarData);
        _lastDeletedData = avatarData;
      }

      await _avatarService.deleteAvatar(avatarId);
    } catch (e) {
      _error = e.toString();
      _lastDeletedAvatar = null;
      _lastDeletedData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> undoDelete() async {
    if (_lastDeletedAvatar == null || _lastDeletedData == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _avatarService.createAvatarWithId(
        _lastDeletedAvatar!.id,
        _lastDeletedData!,
      );

      _lastDeletedAvatar = null;
      _lastDeletedData = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveSampleAvatar(String userId, String name, String imageUrl) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('avatars').add({
        'user_id': userId,
        'name': name,
        'image_url': imageUrl,
        'created_at': FieldValue.serverTimestamp(),
        'metadata': {
          'seed': 'Sample avatar',
        },
      });

    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<Map<String, dynamic>>> getSampleAvatars() {
    return _avatarService.getSampleAvatars();
  }
} 
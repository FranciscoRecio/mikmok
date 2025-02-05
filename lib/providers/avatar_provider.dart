import 'package:flutter/foundation.dart';
import '../models/avatar.dart';
import '../services/avatar_service.dart';

class AvatarProvider extends ChangeNotifier {
  final AvatarService _avatarService = AvatarService();
  List<Avatar> _avatars = [];
  bool _isLoading = false;
  String? _error;

  List<Avatar> get avatars => _avatars;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Avatar>> getUserAvatars(String userId) {
    return _avatarService.getUserAvatars(userId);
  }

  Future<void> createAvatar(String userId, String name, Map<String, dynamic> customization) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _avatarService.createAvatar(userId, name, customization);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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

      await _avatarService.deleteAvatar(avatarId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 
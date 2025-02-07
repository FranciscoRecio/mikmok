import 'package:flutter/foundation.dart';
import '../models/avatar.dart';
import '../services/avatar_service.dart';
import '../services/avatar_generation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class AvatarProvider extends ChangeNotifier {
  final AvatarService _avatarService = AvatarService();
  final AvatarGenerationService _avatarGenerationService = AvatarGenerationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Avatar> _avatars = [];
  bool _isLoading = false;
  String? _error;
  Avatar? _lastDeletedAvatar;
  Map<String, dynamic>? _lastDeletedData;

  List<Avatar> get avatars => _avatars;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Avatar>> getUserAvatars(String userId) {
    return _avatarService.getUserAvatars(userId);
  }

  Future<void> createAvatar(String userId, String prompt, Map<String, dynamic> styleParams) async {
    try {
      _isLoading = true;
      notifyListeners();

      final avatarService = AvatarGenerationService();
      
      // Generate avatar and get task ID
      final taskId = await avatarService.generateAvatar(prompt, styleParams);
      
      // Wait for the final image URL
      final imageUrl = await avatarService.waitForAvatar(taskId);
      print('Got avatar URL: $imageUrl'); // Debug

      // Save to Firestore
      await _firestore.collection('avatars').add({
        'userId': userId,
        'prompt': prompt,
        'imageUrl': imageUrl,
        'name': prompt,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      print('Error creating avatar: $e');
      rethrow;
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

      // Store the avatar data before deleting
      final avatarDoc = await _avatarService.getAvatar(avatarId);
      if (avatarDoc != null) {
        _lastDeletedAvatar = Avatar.fromMap(avatarId, avatarDoc);
        _lastDeletedData = avatarDoc;
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

  Future<void> saveSampleAvatar(String userId, String name, String sampleImageUrl) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Download the sample SVG content
      final response = await http.get(Uri.parse(sampleImageUrl));
      if (response.statusCode != 200) throw 'Failed to download sample avatar';

      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'avatar_$timestamp.svg';
      
      // Upload to Firebase Storage in user's avatars directory
      final storageRef = _storage.ref().child('avatars/$userId/$filename');
      await storageRef.putData(
        response.bodyBytes,
        SettableMetadata(contentType: 'image/svg+xml'),
      );

      // Get the download URL for the uploaded file
      final imageUrl = await storageRef.getDownloadURL();

      // Save to Firestore
      await _firestore.collection('avatars').add({
        'userId': userId,
        'name': name,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'isSample': true,
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      print('Error saving sample avatar: $e');
      rethrow;
    }
  }
} 
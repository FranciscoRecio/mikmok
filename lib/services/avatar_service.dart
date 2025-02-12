import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/avatar.dart';

class AvatarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _baseUrl = 'http://3.128.202.79:8000';

  // Firestore Operations
  Stream<List<Avatar>> getUserAvatars(String userId) {
    return _firestore
        .collection('avatars')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Avatar.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Create a new avatar
  Future<DocumentReference> createAvatar(
    String userId, 
    String name, 
    Map<String, dynamic> customization,
  ) async {
    return _firestore.collection('avatars').add({
      'userId': userId,
      'name': name,
      'imageUrl': '',
      'customization': customization,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update an existing avatar
  Future<void> updateAvatar(String avatarId, String name, Map<String, dynamic> customization) async {
    await _firestore.collection('avatars').doc(avatarId).update({
      'name': name,
      'customization': customization,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete an avatar
  Future<void> deleteAvatar(String avatarId) async {
    await _firestore.collection('avatars').doc(avatarId).delete();
  }

  // Get avatar data
  Future<Map<String, dynamic>?> getAvatar(String avatarId) async {
    final doc = await _firestore.collection('avatars').doc(avatarId).get();
    return doc.data();
  }

  // Create avatar with specific ID (for undo)
  Future<void> createAvatarWithId(String avatarId, Map<String, dynamic> data) async {
    await _firestore.collection('avatars').doc(avatarId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAvatarUrl(String avatarId, String imageUrl) async {
    await _firestore.collection('avatars').doc(avatarId).update({
      'imageUrl': imageUrl,
    });
  }

  // Generation API Operations
  Future<String> startGeneration(String userId, String text) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/generate/avatar/'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'text': text,
        'user_id': userId,
      },
    );

    if (response.statusCode != 200) {
      throw 'Failed to start avatar generation: ${response.statusCode} - ${response.body}';
    }

    final data = json.decode(response.body);
    return data['task_id'] as String;
  }

  Future<Map<String, dynamic>> checkGenerationStatus(String taskId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tasks/$taskId/status/'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw 'Failed to check task status: ${response.statusCode} - ${response.body}';
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  // Add this method to AvatarService
  Stream<List<Map<String, dynamic>>> getSampleAvatars() {
    return _firestore
        .collection('sample_avatars')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                'image_url': data['image_url'] as String? ?? '',
                'name': data['name'] as String? ?? 'Unnamed Avatar',
              };
            })
            .toList());
  }
} 
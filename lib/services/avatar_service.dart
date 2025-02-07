import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/avatar.dart';

class AvatarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all avatars for a user
  Stream<List<Avatar>> getUserAvatars(String userId) {
    return _firestore
        .collection('avatars')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Avatar.fromMap(doc.id, doc.data()))
          .toList();
    });
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
} 
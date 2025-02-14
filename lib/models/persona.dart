import 'package:cloud_firestore/cloud_firestore.dart';

class Persona {
  final String id;
  final String userId;
  final String avatarId;
  final String imageUrl;
  final String name;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
  final bool fromPhoto;

  Persona({
    required this.id,
    required this.userId,
    required this.avatarId,
    required this.imageUrl,
    required this.name,
    required this.createdAt,
    required this.metadata,
    this.fromPhoto = false,
  });

  factory Persona.fromMap(String id, Map<String, dynamic> data) {
    return Persona(
      id: id,
      userId: data['user_id'] as String,
      avatarId: data['avatar_id'] as String,
      imageUrl: data['image_url'] as String,
      name: data['name'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      metadata: data['metadata'] as Map<String, dynamic>,
      fromPhoto: data['from_photo'] as bool? ?? false,
    );
  }

  factory Persona.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Persona(
      id: doc.id,
      userId: data['user_id'],
      avatarId: data['avatar_id'],
      name: data['name'],
      imageUrl: data['image_url'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      metadata: data['metadata'] ?? {},
      fromPhoto: data['from_photo'] ?? false,
    );
  }
} 
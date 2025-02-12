import 'package:cloud_firestore/cloud_firestore.dart';

class Scene {
  final String id;
  final String userId;
  final String personaId;
  final String imageUrl;
  final String name;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  Scene({
    required this.id,
    required this.userId,
    required this.personaId,
    required this.imageUrl,
    required this.name,
    required this.createdAt,
    required this.metadata,
  });

  factory Scene.fromMap(String id, Map<String, dynamic> data) {
    return Scene(
      id: id,
      userId: data['user_id'] as String,
      personaId: data['persona_id'] as String,
      imageUrl: data['image_url'] as String,
      name: data['name'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      metadata: data['metadata'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'persona_id': personaId,
      'image_url': imageUrl,
      'name': name,
      'created_at': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }
} 
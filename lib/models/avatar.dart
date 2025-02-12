import 'package:cloud_firestore/cloud_firestore.dart';

class Avatar {
  final String id;           // document id (same as content_id from backend)
  final String userId;       // user_id
  final String name;         // name
  final String imageUrl;     // image_url
  final DateTime createdAt;  // created_at
  final Map<String, dynamic> metadata;  // metadata (contains seed)

  Avatar({
    required this.id,
    required this.userId,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
    required this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'name': name,
    'image_url': imageUrl,
    'created_at': Timestamp.fromDate(createdAt),
    'metadata': metadata,
  };

  factory Avatar.fromMap(String id, Map<String, dynamic> map) {
    return Avatar(
      id: id,  // document id is the content_id
      userId: map['user_id'] as String,
      name: map['name'] as String,
      imageUrl: map['image_url'] as String,
      createdAt: (map['created_at'] as Timestamp).toDate(),
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  String get seed => metadata['seed'] as String? ?? '';
} 
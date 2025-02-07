import 'package:cloud_firestore/cloud_firestore.dart';

class Avatar {
  final String id;
  final String userId;
  final String name;
  final String imageUrl;
  final Map<String, dynamic> customization;
  final DateTime createdAt;

  Avatar({
    required this.id,
    required this.userId,
    required this.name,
    required this.imageUrl,
    required this.customization,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'imageUrl': imageUrl,
    'customization': customization,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory Avatar.fromMap(String id, Map<String, dynamic> map) {
    return Avatar(
      id: id,
      userId: map['userId'] as String,
      name: map['name'] as String,
      imageUrl: map['imageUrl'] as String? ?? '',
      customization: map['customization'] as Map<String, dynamic>? ?? {},
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
} 
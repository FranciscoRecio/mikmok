import 'package:cloud_firestore/cloud_firestore.dart';

class Avatar {
  final String id;
  final String userId;
  final String name;
  final Map<String, dynamic> customization;
  final DateTime createdAt;
  final DateTime updatedAt;

  Avatar({
    required this.id,
    required this.userId,
    required this.name,
    required this.customization,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'customization': customization,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Avatar.fromMap(String id, Map<String, dynamic> map) {
    return Avatar(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      customization: map['customization'] ?? {},
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
} 
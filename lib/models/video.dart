import 'package:cloud_firestore/cloud_firestore.dart';

class Video {
  final String contentId;
  final String userId;
  final String videoUrl;
  final String thumbnailUrl;
  final String name;
  final DateTime createdAt;
  final VideoMetadata metadata;

  Video({
    required this.contentId,
    required this.userId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.name,
    required this.createdAt,
    required this.metadata,
  });

  factory Video.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Video(
      contentId: doc.id,
      userId: data['user_id'] as String,
      videoUrl: data['video_url'] as String,
      thumbnailUrl: data['thumbnail_url'] as String,
      name: data['name'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      metadata: VideoMetadata.fromMap(data['metadata'] as Map<String, dynamic>),
    );
  }
}

class VideoMetadata {
  final String prompt;
  final String startImageUrl;
  final String? endImageUrl;

  VideoMetadata({
    required this.prompt,
    required this.startImageUrl,
    this.endImageUrl,
  });

  factory VideoMetadata.fromMap(Map<String, dynamic> map) {
    return VideoMetadata(
      prompt: map['prompt'] as String,
      startImageUrl: map['start_image_url'] as String,
      endImageUrl: map['end_image_url'] as String?,
    );
  }
} 
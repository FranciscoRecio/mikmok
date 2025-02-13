import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoGenerationService {
  final String baseUrl = 'http://3.128.202.79:8000';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> generateAvatarVideo(String text, List<int> imageBytes, String userId) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/generate/video/'));
      request.headers.addAll({
        'accept': 'application/json',
      });

      // Add text and required fields
      request.fields['text'] = text;
      request.fields['style_params'] = '{}';
      request.fields['user_id'] = userId;
      request.fields['is_sample'] = 'true'; // For now, using sample videos

      // Add the image file directly from bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: 'avatar.svg',
          contentType: MediaType('image', 'svg+xml'),
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200) {
        return data['task_id'];
      } else {
        throw Exception('Failed to generate video: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating video: $e');
      rethrow;
    }
  }

  Future<String> waitForVideo(String taskId) async {
    while (true) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/status/$taskId'),
          headers: {'accept': 'application/json'},
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to check status: ${response.statusCode}');
        }

        final status = json.decode(response.body);
        
        if (status['status'] == 'SUCCESS') {
          final result = status['result'];
          if (result != null && result['video_url'] != null) {
            return result['video_url'];
          }
          throw Exception('No video URL in result');
        }
        
        if (status['status'] == 'FAILURE') {
          throw Exception(status['error'] ?? 'Video generation failed');
        }
        
        print('Still processing, waiting 2 seconds...'); // Debug
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        print('Error checking status: $e'); // Debug
        rethrow;
      }
    }
  }

  Future<String> generateSceneToVideo({
    required String prompt,
    required String userId,
    required String startImageUrl,
    String? endImageUrl,
  }) async {
    try {
      // Create form data
      final formData = {
        'prompt': prompt,
        'user_id': userId,
        'start_image_url': startImageUrl,
      };

      // Add end_image_url if provided
      if (endImageUrl != null) {
        formData['end_image_url'] = endImageUrl;
      }

      // Make request
      final response = await http.post(
        Uri.parse('$baseUrl/generate/scene-to-video/'),
        headers: {'accept': 'application/json'},
        body: formData,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate video: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      return data['task_id'];
    } catch (e) {
      print('Error generating video: $e');
      rethrow;
    }
  }

  Future<void> deleteVideo(String videoId) async {
    try {
      await _firestore.collection('videos').doc(videoId).update({
        'user_id': 'archive',  // Mark as archived instead of deleting
        'archived_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error archiving video: $e');
      rethrow;
    }
  }

  Future<void> updateVideo(String videoId, {String? name}) async {
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('videos').doc(videoId).update(updates);
    } catch (e) {
      print('Error updating video: $e');
      rethrow;
    }
  }

  Future<String> generateVideo({
    required String prompt,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate/video/'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'prompt': prompt,
        'user_id': userId,
      },
    );

    if (response.statusCode != 200) {
      throw 'Failed to start video generation: ${response.statusCode} - ${response.body}';
    }

    final data = json.decode(response.body);
    return data['task_id'] as String;
  }
} 
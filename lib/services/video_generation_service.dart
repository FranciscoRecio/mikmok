import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';

class VideoGenerationService {
  final String baseUrl = 'http://13.58.155.61:8000';
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> generateVideo(String text, String imageUrl) async {
    try {
      // Download the SVG image first
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) {
        throw Exception('Failed to download avatar image');
      }

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/generate/video/'));
      request.headers.addAll({
        'accept': 'application/json',
      });

      // Add text and style params
      request.fields['text'] = text;
      request.fields['style_params'] = '{}';

      // Add the image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          imageResponse.bodyBytes,
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
            final sourceUrl = result['video_url'];
            print('Got source URL: $sourceUrl'); // Debug
            
            // Download video
            final videoResponse = await http.get(Uri.parse(sourceUrl));
            if (videoResponse.statusCode != 200) {
              throw Exception('Failed to download video');
            }

            // Upload to Firebase Storage
            final ref = _storage.ref().child('videos/$taskId.mp4');
            await ref.putData(
              videoResponse.bodyBytes,
              SettableMetadata(contentType: 'video/mp4'),
            );

            // Get Firebase Storage URL
            final firebaseUrl = await ref.getDownloadURL();
            print('Uploaded to Firebase: $firebaseUrl'); // Debug
            
            return firebaseUrl;
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
} 
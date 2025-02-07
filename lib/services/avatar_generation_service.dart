import 'package:http/http.dart' as http;
import 'dart:convert';

class AvatarGenerationService {
  final String baseUrl = 'http://3.128.202.79:8000';

  // Start avatar generation
  Future<String> generateAvatar(String text, Map<String, dynamic> styleParams) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/generate/avatar/'));
      request.headers.addAll({
        'accept': 'application/json',
      });

      request.fields['text'] = text;
      request.fields['style_params'] = json.encode(styleParams);

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200) {
        return data['task_id'];
      } else {
        throw Exception('Failed to generate avatar: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating avatar: $e');
      rethrow;
    }
  }

  // Check generation status
  Future<Map<String, dynamic>> checkStatus(String taskId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/status/$taskId'),
      headers: {'accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to check status');
    }
  }

  // Poll until avatar is ready
  Future<String> waitForAvatar(String taskId) async {
    print('Starting to wait for avatar...'); // Debug
    print('Task ID: $taskId'); // Debug

    while (true) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/status/$taskId'),
          headers: {'accept': 'application/json'},
        );

        print('Status response code: ${response.statusCode}'); // Debug
        print('Status response body: ${response.body}'); // Debug

        if (response.statusCode != 200) {
          throw Exception('Failed to check status: ${response.statusCode}');
        }

        final status = json.decode(response.body);
        
        if (status['status'] == 'SUCCESS') {
          final result = status['result'];
          if (result != null && result['image_url'] != null) {
            return result['image_url'];
          }
          throw Exception('No image URL in result');
        }
        
        if (status['status'] == 'FAILURE') {
          throw Exception(status['error'] ?? 'Avatar generation failed');
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
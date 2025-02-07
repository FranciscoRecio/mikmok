import 'package:http/http.dart' as http;
import 'dart:convert';

class AvatarGenerationService {
  final String baseUrl = 'http://13.58.155.61:8000';

  // Start avatar generation
  Future<String> generateAvatar(String text, Map<String, dynamic> styleParams) async {
    try {
      print('Making API request to generate avatar...'); // Debug
      print('Text: $text'); // Debug
      
      // URL encode the text
      final encodedText = Uri.encodeComponent(text);
      print('Encoded text: $encodedText'); // Debug

      final response = await http.post(
        Uri.parse('$baseUrl/generate/avatar/'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'accept': 'application/json',
        },
        body: {
          'text': encodedText, // Use encoded text
          'style_params': json.encode(styleParams),
        },
      );

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['task_id'];
      } else {
        throw Exception('Failed to generate avatar: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error generating avatar: $e'); // Debug
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
          if (result != null && result['thumbnail_url'] != null) {
            final url = result['thumbnail_url'].toString();
            
            // URL encode the seed parameter if it's a DiceBear URL
            if (url.contains('dicebear.com') && url.contains('seed=')) {
              final uri = Uri.parse(url);
              final seed = uri.queryParameters['seed'];
              if (seed != null) {
                final encodedSeed = Uri.encodeComponent(seed);
                final newUrl = url.replaceAll('seed=$seed', 'seed=$encodedSeed');
                print('Encoded URL: $newUrl'); // Debug
                return newUrl;
              }
            }
            
            print('Success! Got URL: $url'); // Debug
            return url;
          }
          throw Exception('No thumbnail URL in result');
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
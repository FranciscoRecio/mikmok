import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/scene.dart';

class SceneService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _baseUrl = 'http://3.128.202.79:8000';  // Update with your API URL

  Stream<List<Scene>> getUserScenesForPersona(String userId, String personaId) {
    return _firestore
        .collection('scenes')
        .where('user_id', isEqualTo: userId)
        .where('persona_id', isEqualTo: personaId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Scene.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<String> startGeneration({
    required String prompt,
    required String userId,
    required String personaId,
    required String personaUrl,
  }) async {
    final formData = {
      'prompt': prompt,
      'user_id': userId,
      'persona_id': personaId,
      'persona_url': personaUrl,
    };

    print('Starting scene generation with form data:');
    print(formData);

    final response = await http.post(
      Uri.parse('$_baseUrl/generate/persona-to-scene/'),
      headers: {
        'Accept': 'application/json',
      },
      body: formData,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw 'Failed to start scene generation: ${response.statusCode} - ${response.body}';
    }

    final data = json.decode(response.body);
    return data['task_id'] as String;
  }

  Future<void> deleteScene(String sceneId) async {
    await _firestore.collection('scenes').doc(sceneId).delete();
  }

  Future<Map<String, dynamic>> checkGenerationStatus(String taskId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/status/$taskId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw 'Failed to check task status: ${response.statusCode} - ${response.body}';
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }
} 
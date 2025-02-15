import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/persona.dart';

class PersonaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _baseUrl = 'http://3.128.202.79:8000';

  // Firestore Operations
  Stream<List<Persona>> getUserPersonas(String userId) {
    return _firestore
        .collection('personas')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Persona.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<Map<String, dynamic>?> getPersona(String personaId) async {
    final doc = await _firestore.collection('personas').doc(personaId).get();
    return doc.data();
  }

  Future<void> deletePersona(String personaId) async {
    await _firestore.collection('personas').doc(personaId).delete();
  }

  Future<void> createPersonaWithId(String personaId, Map<String, dynamic> data) async {
    await _firestore.collection('personas').doc(personaId).set(data);
  }

  // API Operations
  Future<String> startGeneration({
    required String name,
    required String userId,
    required String avatarId,
    required String avatarUrl,
    String? prompt,
  }) async {
    final formData = {
      'name': name,
      'user_id': userId,
      'avatar_id': avatarId,
      'avatar_url': avatarUrl,
      if (prompt != null) 'prompt': prompt,
    };

    print('Starting persona generation with form data:');
    print(formData);

    final response = await http.post(
      Uri.parse('$_baseUrl/generate/avatar-to-persona/'),
      headers: {
        'Accept': 'application/json',
      },
      body: formData,  // Send as form data instead of JSON
    );

    print('Request URL: ${Uri.parse('$_baseUrl/generate/avatar-to-persona/')}');
    print('Request headers:');
    print(response.request?.headers);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw 'Failed to start persona generation: ${response.statusCode} - ${response.body}';
    }

    final data = json.decode(response.body);
    return data['task_id'] as String;
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

  Stream<List<Persona>> getUserPersonasForAvatar(String userId, String avatarId) {
    return _firestore
        .collection('personas')
        .where('user_id', isEqualTo: userId)
        .where('avatar_id', isEqualTo: avatarId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Persona.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<String> startPhotoGeneration({
    required String userId,
    required String name,
    required String photoPath,
    int style = 0,
  }) async {
    final photoUrl = await uploadPhoto(photoPath, userId);
    
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/generate/photo-to-persona/'),
    );
    
    request.fields['user_id'] = userId;
    request.fields['avatar_id'] = name;  // Use name as avatar_id
    request.fields['name'] = name;
    request.fields['style'] = style.toString();
    request.fields['avatar_url'] = photoUrl;

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final data = json.decode(responseData);

    if (response.statusCode != 200) {
      throw 'Failed to start photo generation: ${response.statusCode}';
    }

    return data['task_id'];
  }

  Future<String> uploadPhoto(String photoPath, String userId) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload/photo/'),
    );
    
    request.fields['user_id'] = userId;
    request.fields['folder'] = 'temp_photos';
    request.files.add(await http.MultipartFile.fromPath('file', photoPath));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final data = json.decode(responseData);

    if (response.statusCode != 200) {
      throw 'Failed to upload photo: ${response.statusCode}';
    }

    return data['url'];
  }
} 
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
    final response = await http.post(
      Uri.parse('$_baseUrl/generate/persona/'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'name': name,
        'user_id': userId,
        'avatar_id': avatarId,
        'avatar_url': avatarUrl,
        if (prompt != null) 'prompt': prompt,
      },
    );

    if (response.statusCode != 200) {
      throw 'Failed to start persona generation: ${response.statusCode} - ${response.body}';
    }

    final data = json.decode(response.body);
    return data['task_id'] as String;
  }

  Future<Map<String, dynamic>> checkGenerationStatus(String taskId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tasks/$taskId/status/'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw 'Failed to check task status: ${response.statusCode} - ${response.body}';
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }
} 
import 'package:flutter/foundation.dart';
import '../models/persona.dart';
import '../services/persona_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PersonaProvider extends ChangeNotifier {
  final PersonaService _personaService = PersonaService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _error;
  Persona? _lastDeletedPersona;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Persona>> getUserPersonasForAvatar(String userId, String avatarId) {
    return _personaService.getUserPersonasForAvatar(userId, avatarId);
  }

  Future<void> deletePersona(String personaId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final personaData = await _personaService.getPersona(personaId);
      if (personaData != null) {
        _lastDeletedPersona = Persona.fromMap(personaId, personaData);
      }

      await _personaService.deletePersona(personaId);
    } catch (e) {
      _error = e.toString();
      _lastDeletedPersona = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> undoDelete() async {
    if (_lastDeletedPersona == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _personaService.createPersonaWithId(
        _lastDeletedPersona!.id,
        {
          'user_id': _lastDeletedPersona!.userId,
          'avatar_id': _lastDeletedPersona!.avatarId,
          'image_url': _lastDeletedPersona!.imageUrl,
          'name': _lastDeletedPersona!.name,
          'created_at': _lastDeletedPersona!.createdAt,
          'metadata': _lastDeletedPersona!.metadata,
        },
      );

      _lastDeletedPersona = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> startGeneration({
    required String name,
    required String userId,
    required String avatarId,
    required String avatarUrl,
    String? prompt,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final taskId = await _personaService.startGeneration(
        name: name,
        userId: userId,
        avatarId: avatarId,
        avatarUrl: avatarUrl,
        prompt: prompt,
      );

      return taskId;
    } catch (e) {
      _error = e.toString();
      throw _error!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> checkGenerationStatus(String taskId) async {
    try {
      return await _personaService.checkGenerationStatus(taskId);
    } catch (e) {
      _error = e.toString();
      throw _error!;
    }
  }

  Stream<List<Persona>> getUserPersonas(String userId, {required bool isVirtual}) {
    return _firestore
        .collection('personas')
        .where('user_id', isEqualTo: userId)
        .where('from_photo', isEqualTo: isVirtual)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Persona.fromFirestore(doc))
            .toList());
  }

  Future<void> updatePersona(String personaId, {String? name}) async {
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('personas').doc(personaId).update(updates);
    } catch (e) {
      print('Error updating persona: $e');
      rethrow;
    }
  }
} 
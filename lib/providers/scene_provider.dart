import 'package:flutter/foundation.dart';
import '../models/scene.dart';
import '../services/scene_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SceneProvider extends ChangeNotifier {
  final SceneService _sceneService = SceneService();
  bool _isLoading = false;
  String? _error;
  Scene? _lastDeletedScene;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Scene>> getUserScenesForPersona(String userId, String personaId) {
    return _sceneService.getUserScenesForPersona(userId, personaId);
  }

  Future<String> startGeneration({
    required String prompt,
    required String userId,
    required String personaId,
    required String personaUrl,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final taskId = await _sceneService.startGeneration(
        prompt: prompt,
        userId: userId,
        personaId: personaId,
        personaUrl: personaUrl,
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

  Future<void> deleteScene(String sceneId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _sceneService.deleteScene(sceneId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> checkGenerationStatus(String taskId) async {
    try {
      return await _sceneService.checkGenerationStatus(taskId);
    } catch (e) {
      _error = e.toString();
      throw _error!;
    }
  }

  Future<String> startSceneToSceneGeneration({
    required String prompt,
    required String userId,
    required String personaId,
    required String sceneUrl,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final taskId = await _sceneService.startSceneToSceneGeneration(
        prompt: prompt,
        userId: userId,
        personaId: personaId,
        sceneUrl: sceneUrl,
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

  Future<void> updateScene(String sceneId, {String? name}) async {
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('scenes').doc(sceneId).update(updates);
    } catch (e) {
      print('Error updating scene: $e');
      rethrow;
    }
  }
} 
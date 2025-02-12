import 'package:flutter/foundation.dart';
import '../models/scene.dart';
import '../services/scene_service.dart';

class SceneProvider extends ChangeNotifier {
  final SceneService _sceneService = SceneService();
  bool _isLoading = false;
  String? _error;
  Scene? _lastDeletedScene;

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
} 
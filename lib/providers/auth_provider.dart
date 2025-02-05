import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;

  AuthProvider() {
    debugPrint('AuthProvider initialized');
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      debugPrint('Auth state change detected in stream');
      updateUser(user);
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  void updateUser(User? user) {
    debugPrint('updateUser called with: ${user?.email}');
    if (_user?.uid != user?.uid) {
      debugPrint('User changed, updating state');
      _user = user;
      notifyListeners();
      debugPrint('State updated, notified listeners');
    } else {
      debugPrint('User unchanged, skipping update');
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
} 
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      updateUser(user);
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  void updateUser(User? user) {
    if (_user?.uid != user?.uid) {
      _user = user;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
} 
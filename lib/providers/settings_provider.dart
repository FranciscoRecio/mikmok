import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isVirtual = true;
  
  bool get isVirtual => _isVirtual;
  
  void setIsVirtual(bool value) {
    _isVirtual = value;
    notifyListeners();
  }
} 
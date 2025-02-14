// lib/providers/db_state_provider.dart

import 'package:flutter/material.dart';

class DBStateProvider extends ChangeNotifier {
  bool _isConnected = false;
  bool _needsReset = false;
  String? _errorMessage;

  bool get isConnected => _isConnected;
  bool get needsReset => _needsReset;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  void setConnectionState(bool connected, {String? error}) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _errorMessage = error;
      notifyListeners();
    }
  }

  void triggerReset(String error) {
    _needsReset = true;
    _errorMessage = error;
    _isConnected = false;
    notifyListeners();
  }

  void resetCompleted() {
    _needsReset = false;
    _errorMessage = null;
    notifyListeners();
  }
}
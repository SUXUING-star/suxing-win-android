// lib/providers/initialization_provider.dart
import 'package:flutter/material.dart';
import '../widgets/startup/initialization_screen.dart';

class InitializationProvider extends ChangeNotifier {
  InitializationStatus _status = InitializationStatus.inProgress;
  String _message = '正在初始化...';
  double _progress = 0.0;

  InitializationStatus get status => _status;
  String get message => _message;
  double get progress => _progress;

  void updateProgress(String message, double progress) {
    _message = message;
    _progress = progress;
    _status = InitializationStatus.inProgress;
    notifyListeners();
  }

  void setError(String errorMessage) {
    _message = errorMessage;
    _status = InitializationStatus.error;
    notifyListeners();
  }

  void setCompleted() {
    _status = InitializationStatus.completed;
    _progress = 1.0;
    notifyListeners();
  }

  void reset() {
    _status = InitializationStatus.inProgress;
    _message = '正在初始化...';
    _progress = 0.0;
    notifyListeners();
  }
}
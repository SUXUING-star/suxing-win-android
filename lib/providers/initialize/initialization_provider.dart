// lib/providers/initialize/initialization_provider.dart
import 'package:flutter/material.dart';
import '../../widgets/common/startup/initialization_screen.dart';
import '../../utils/error/error_formatter.dart';

class InitializationProvider extends ChangeNotifier {
  InitializationStatus _status = InitializationStatus.inProgress;
  String _message = '正在初始化...';
  double _progress = 0.0;
  bool _isDisposed = false;

  InitializationStatus get status => _status;
  String get message => _message;
  double get progress => _progress;

  void updateProgress(String message, double progress) {
    if (_isDisposed) return;

    // 确保进度只能前进，不能后退
    if (progress >= _progress) {
      _message = message;
      _progress = progress;
      _status = InitializationStatus.inProgress;
      notifyListeners();
    }
  }

  void setError(String error) {
    if (_isDisposed) return;
    _message = error;
    _status = InitializationStatus.error;
    notifyListeners();
  }

  void setCompleted() {
    if (_isDisposed) return;
    _progress = 1.0;
    _status = InitializationStatus.completed;
    notifyListeners();
  }

  void reset() {
    if (_isDisposed) return;
    _status = InitializationStatus.inProgress;
    _message = '正在初始化...';
    _progress = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
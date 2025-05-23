// lib/providers/navigation/sidebar_provider.dart
import 'dart:async'; // Import async
import 'package:flutter/material.dart';

class SidebarProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isSubRouteActive = false;

  final _indexController = StreamController<int>.broadcast();
  final _subRouteActiveController = StreamController<bool>.broadcast();

  Stream<int> get indexStream => _indexController.stream;
  Stream<bool> get subRouteActiveStream => _subRouteActiveController.stream;

  int get currentIndex => _currentIndex;
  bool get isSubRouteActive => _isSubRouteActive;

  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      _indexController.add(index);
      notifyListeners();
    }
  }

  void setSubRouteActive(bool isActive) {
    if (_isSubRouteActive != isActive) {
      _isSubRouteActive = isActive;
      _subRouteActiveController.add(isActive);
      notifyListeners();
    }
  }

  // Don't forget to close the stream controller
  @override
  void dispose() {
    _indexController.close();
    _subRouteActiveController.close();
    super.dispose();
  }
}
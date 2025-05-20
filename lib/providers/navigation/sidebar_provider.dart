// lib/providers/navigation/sidebar_provider.dart
import 'package:flutter/material.dart';

class SidebarProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isSubRouteActive = false; // <-- Add this state variable

  int get currentIndex => _currentIndex;
  bool get isSubRouteActive => _isSubRouteActive; // <-- Add getter

  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
  // --- Add method to update sub-route status ---
  void setSubRouteActive(bool isActive) {
    if (_isSubRouteActive != isActive) {
      _isSubRouteActive = isActive;
      notifyListeners();
    }
  }
}
import 'package:flutter/material.dart';
// --- RefreshController 类 (保持不变) ---
class RefreshController {
  VoidCallback? _onRefreshCompletedCallback;
  void addListener(VoidCallback listener) {
    _onRefreshCompletedCallback = listener;
  }

  void refreshCompleted() {
    _onRefreshCompletedCallback?.call();
  }

  void dispose() {
    _onRefreshCompletedCallback = null;
  }
}
// lib/providers/windows/window_state_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

class WindowStateProvider with ChangeNotifier, WindowListener {
  bool _isResizingWindow = false;
  Timer? _resizeEndTimer;
  static const Duration _resizeDebounceDuration = Duration(milliseconds: 300);
  bool _isDraggingTitleBar = false;

  // --- Stream Controller and Stream for isResizingWindow ---
  final _isResizingWindowController = StreamController<bool>.broadcast();
  Stream<bool> get isResizingWindowStream => _isResizingWindowController.stream;

  // --- Getter for initial state or non-stream access ---
  bool get isResizingWindow => _isResizingWindow;

  WindowStateProvider() {
    // 初始化时发送初始状态
    _isResizingWindowController.add(_isResizingWindow);

    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return;
    }
    windowManager.addListener(this);
  }

  void _updateIsResizingWindowState(bool newValue) {
    if (_isResizingWindow == newValue) return; // 状态未改变，则不通知
    _isResizingWindow = newValue;
    _isResizingWindowController.add(_isResizingWindow);
  }

  void _startResizingOrTitleBarDragging() {
    _updateIsResizingWindowState(true);
    _resizeEndTimer?.cancel();
  }

  void _endResizingOrTitleBarDragging() {
    _resizeEndTimer = Timer(_resizeDebounceDuration, () {
      if (_isResizingWindow && !_isDraggingTitleBar) {
        _updateIsResizingWindowState(false);
      }
    });
  }

  void notifyTitleBarDragStart() {
    _isDraggingTitleBar = true;
    _startResizingOrTitleBarDragging();
  }

  void notifyTitleBarDragEnd() {
    _isDraggingTitleBar = false;
    _endResizingOrTitleBarDragging();
  }

  @override
  void onWindowResize() {
    _startResizingOrTitleBarDragging();
    _endResizingOrTitleBarDragging();
  }

  // ... (other WindowListener methods remain the same: onWindowMove, onWindowClose, etc.)
  @override
  void onWindowMove() {}
  @override
  void onWindowClose() {}
  @override
  void onWindowFocus() {}
  @override
  void onWindowBlur() {}
  @override
  void onWindowMaximize() {}
  @override
  void onWindowUnmaximize() {}
  @override
  void onWindowMinimize() {}
  @override
  void onWindowRestore() {}
  @override
  void onWindowEnterFullScreen() {}
  @override
  void onWindowLeaveFullScreen() {}

  @override
  void dispose() {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      windowManager.removeListener(this);
    }
    _resizeEndTimer?.cancel();
    _isResizingWindowController.close(); // ⭐ 关闭 StreamController
    super.dispose();
  }
}

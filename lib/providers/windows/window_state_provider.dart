// providers/window_state_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowStateProvider with ChangeNotifier, WindowListener {
  bool _isResizingWindow = false;
  bool get isResizingWindow => _isResizingWindow;

  Timer? _resizeEndTimer;
  static const Duration _resizeDebounceDuration = Duration(milliseconds: 300);

  bool _isDraggingTitleBar = false; // 标记是否正在拖拽标题栏

  WindowStateProvider() {
    if (kIsWeb || !(defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS)) {
      return;
    }
    windowManager.addListener(this);
  }

  void _startResizingOrTitleBarDragging() {
    if (!_isResizingWindow) {
      _isResizingWindow = true;
      notifyListeners();
    }
    _resizeEndTimer?.cancel();
  }

  void _endResizingOrTitleBarDragging() {
    _resizeEndTimer = Timer(_resizeDebounceDuration, () {
      // 只有当窗口尺寸调整和标题栏拖拽都结束时，才真正结束 _isResizingWindow 状态
      if (_isResizingWindow && !_isDraggingTitleBar) { // 确保标题栏拖拽也结束了
        // 如果 resize 事件自身也停止了（由 _resizeDebounceDuration 控制），才设置为 false
        _isResizingWindow = false;
        notifyListeners();
      }
    });
  }

  // --- 给 DesktopFrameLayout 中的 DragToMoveArea (标题栏拖拽) 使用 ---
  void notifyTitleBarDragStart() {
    _isDraggingTitleBar = true;
    _startResizingOrTitleBarDragging(); // 拖拽标题栏开始，视为调整开始
  }

  void notifyTitleBarDragEnd() {
    _isDraggingTitleBar = false;
    // 拖拽标题栏结束，尝试结束调整状态（会由防抖处理）
    // 如果此时没有 onWindowResize 事件在持续触发，那么防抖后状态会变为 false
    _endResizingOrTitleBarDragging();
  }

  // --- WindowListener Callbacks ---
  @override
  void onWindowResize() {
    // 窗口尺寸变化时，启动/重置调整状态
    _startResizingOrTitleBarDragging();
    _endResizingOrTitleBarDragging();
  }

  @override
  void onWindowMove() {
    // 窗口移动不触发“正在调整大小”的状态
  }

  @override
  void onWindowClose() {
    // 窗口关闭事件
  }

  @override
  void onWindowFocus() {
    // 窗口获得焦点事件
  }

  @override
  void onWindowBlur() {
    // 窗口失去焦点事件
  }

  @override
  void onWindowMaximize() {
    // 窗口最大化事件
    // 如果最大化/取消最大化也算一种“尺寸调整”，可以在这里调用
    // _startResizingOrTitleBarDragging();
    // _endResizingOrTitleBarDragging();
    // 但通常最大化/取消最大化是瞬间完成的，可能不需要屏保。看你的需求。
  }

  @override
  void onWindowUnmaximize() {
    // 窗口取消最大化事件
  }

  @override
  void onWindowMinimize() {
    // 窗口最小化事件
  }

  @override
  void onWindowRestore() {
    // 窗口从最小化恢复事件
  }

  @override
  void onWindowEnterFullScreen() {
    // 窗口进入全屏事件
  }

  @override
  void onWindowLeaveFullScreen() {
    // 窗口离开全屏事件
  }

  // 如果 window_manager 将来增加了新的事件，也应该在这里添加对应的方法。
  // 例如：
  // @override
  // void onWindowDocked() {}
  // @override
  // void onWindowUndocked() {}

  @override
  void dispose() {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS)) {
      windowManager.removeListener(this);
    }
    _resizeEndTimer?.cancel();
    super.dispose();
  }
}
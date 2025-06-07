// lib/providers/windows/window_state_provider.dart

/// 该文件定义了 WindowStateProvider，一个管理窗口状态的 ChangeNotifier。
/// WindowStateProvider 跟踪窗口的拖拽和尺寸调整状态。
library;


import 'dart:async'; // 异步编程所需
import 'package:flutter/foundation.dart'; // 平台判断所需
import 'package:window_manager/window_manager.dart'; // 窗口管理库

/// `WindowStateProvider` 类：管理窗口状态的 Provider。
///
/// 该类通过监听窗口事件来提供窗口的尺寸调整和拖拽状态。
class WindowStateProvider with ChangeNotifier, WindowListener {
  bool _isResizingWindow = false; // 标识窗口是否正在调整尺寸
  Timer? _resizeEndTimer; // 用于尺寸调整结束的防抖计时器
  static const Duration _resizeDebounceDuration =
      Duration(milliseconds: 300); // 尺寸调整防抖延迟
  bool _isDraggingTitleBar = false; // 标识标题栏是否正在被拖拽

  // --- Stream 控制器和 Stream ---
  final _isResizingWindowController =
      StreamController<bool>.broadcast(); // 广播窗口尺寸调整状态的控制器

  /// 获取窗口尺寸调整状态的 Stream。
  Stream<bool> get isResizingWindowStream => _isResizingWindowController.stream;

  // --- 同步获取器 ---
  /// 获取当前窗口尺寸调整状态。
  bool get isResizingWindow => _isResizingWindow;

  /// 构造函数。
  ///
  /// 构造时广播初始状态。
  /// 仅在桌面平台（Windows, Linux, macOS）上添加窗口监听器。
  WindowStateProvider() {
    _isResizingWindowController.add(_isResizingWindow); // 广播初始状态

    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return;
    }
    windowManager.addListener(this); // 添加窗口事件监听器
  }

  /// 私有辅助方法：更新 `_isResizingWindow` 状态。
  ///
  /// [newValue]：新的窗口尺寸调整状态。
  void _updateIsResizingWindowState(bool newValue) {
    if (_isResizingWindow == newValue) return; // 状态未改变则不处理
    _isResizingWindow = newValue; // 更新内部状态
    _isResizingWindowController.add(_isResizingWindow); // 广播新状态
  }

  /// 启动窗口尺寸调整或标题栏拖拽的逻辑。
  ///
  /// 设置窗口为调整尺寸状态，并取消任何现有防抖计时器。
  void _startResizingOrTitleBarDragging() {
    _updateIsResizingWindowState(true); // 设置为调整尺寸状态
    _resizeEndTimer?.cancel(); // 取消之前的计时器
  }

  /// 结束窗口尺寸调整或标题栏拖拽的逻辑。
  ///
  /// 启动防抖计时器，在延迟后将窗口调整尺寸状态设为 false。
  void _endResizingOrTitleBarDragging() {
    _resizeEndTimer = Timer(_resizeDebounceDuration, () {
      // 启动防抖计时器
      if (_isResizingWindow && !_isDraggingTitleBar) {
        // 在调整尺寸且未拖拽标题栏时才结束状态
        _updateIsResizingWindowState(false); // 设置为非调整尺寸状态
      }
    });
  }

  /// 通知标题栏拖拽开始。
  void notifyTitleBarDragStart() {
    _isDraggingTitleBar = true; // 设置标题栏拖拽状态
    _startResizingOrTitleBarDragging(); // 启动调整尺寸/拖拽逻辑
  }

  /// 通知标题栏拖拽结束。
  void notifyTitleBarDragEnd() {
    _isDraggingTitleBar = false; // 清除标题栏拖拽状态
    _endResizingOrTitleBarDragging(); // 结束调整尺寸/拖拽逻辑
  }

  /// 窗口尺寸调整事件回调。
  @override
  void onWindowResize() {
    _startResizingOrTitleBarDragging(); // 启动调整尺寸逻辑
    _endResizingOrTitleBarDragging(); // 结束调整尺寸逻辑
  }

  /// 窗口移动事件回调。
  @override
  void onWindowMove() {}

  /// 窗口关闭事件回调。
  @override
  void onWindowClose() {}

  /// 窗口获得焦点事件回调。
  @override
  void onWindowFocus() {}

  /// 窗口失去焦点事件回调。
  @override
  void onWindowBlur() {}

  /// 窗口最大化事件回调。
  @override
  void onWindowMaximize() {}

  /// 窗口取消最大化事件回调。
  @override
  void onWindowUnmaximize() {}

  /// 窗口最小化事件回调。
  @override
  void onWindowMinimize() {}

  /// 窗口恢复事件回调。
  @override
  void onWindowRestore() {}

  /// 窗口进入全屏事件回调。
  @override
  void onWindowEnterFullScreen() {}

  /// 窗口离开全屏事件回调。
  @override
  void onWindowLeaveFullScreen() {}

  /// 清理资源。
  ///
  /// 在桌面平台移除窗口监听器，取消计时器，并关闭 StreamController。
  @override
  void dispose() {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      windowManager.removeListener(this); // 移除窗口监听器
    }
    _resizeEndTimer?.cancel(); // 取消计时器
    _isResizingWindowController.close(); // 关闭 StreamController
    super.dispose(); // 调用父类销毁方法
  }
}

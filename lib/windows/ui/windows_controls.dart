// lib/windows/ui/windows_controls.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 假设这个是你自定义的扩展
import 'package:suxingchahui/windows/ui/control_button.dart';
import 'package:window_manager/window_manager.dart';

class WindowsControls extends StatefulWidget {
  final Color? iconColor;
  final Color? hoverColor;
  final Color? closeHoverColor;

  const WindowsControls({
    super.key,
    this.iconColor,
    this.hoverColor,
    this.closeHoverColor,
  });

  @override
  State<WindowsControls> createState() => _WindowsControlsState();
}

class _WindowsControlsState extends State<WindowsControls> with WindowListener {
  bool _isMaximized = false;
  bool _isInitialized = false; // 用于确保 _updateMaximizeState 只在初始化时执行一次异步

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    // 异步获取初始状态，并确保只执行一次
    _initializeMaximizeState();
  }

  Future<void> _initializeMaximizeState() async {
    // 防止在 hot reload 或其他情况下重复执行异步操作
    if (_isInitialized || !mounted) return;
    _isInitialized = true; // 标记已尝试初始化

    try {
      final maximized = await windowManager.isMaximized();
      if (mounted) { // 异步操作后再次检查 mounted
        setState(() {
          _isMaximized = maximized;
        });
      }
    } catch (e) {
      // 处理可能的异常，例如 windowManager 尚未完全准备好
      // print("Error getting initial maximized state: $e");
      if (mounted) {
        // 可以选择一个默认值或再次尝试
        setState(() {
          _isMaximized = false; // 发生错误时默认为未最大化
        });
      }
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  // WindowListener methods
  @override
  void onWindowMaximize() {
    if (mounted && !_isMaximized) { // 只有当状态真正改变时才 setState
      setState(() => _isMaximized = true);
    }
  }

  @override
  void onWindowUnmaximize() {
    if (mounted && _isMaximized) { // 只有当状态真正改变时才 setState
      setState(() => _isMaximized = false);
    }
  }

  // 其他 onWindow... 方法如果不需要可以省略，或者保持空实现
  @override
  void onWindowFocus() {}
  @override
  void onWindowBlur() {}
  @override
  void onWindowMinimize() {}
  @override
  void onWindowRestore() {}
  @override
  void onWindowResize() {}
  @override
  void onWindowMove() {}
  @override
  void onWindowEnterFullScreen() {}
  @override
  void onWindowLeaveFullScreen() {}


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color currentIconColor = widget.iconColor ??
        theme.colorScheme.onSurface.withSafeOpacity(0.8);
    final Color currentHoverColor = widget.hoverColor ??
        theme.colorScheme.onSurface.withSafeOpacity(0.1);
    final Color currentCloseHoverColor = widget.closeHoverColor ?? Colors.red;

    const double iconSize = 16.0;

    return SizedBox(
      height: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ControlButton(
            icon: Icons.minimize,
            iconSize: iconSize,
            iconColor: currentIconColor,
            hoverColor: currentHoverColor,
            onPressed: () => windowManager.minimize(), // 直接调用，不 await
            tooltip: '最小化',
          ),
          ControlButton(
            icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
            iconSize: iconSize,
            iconColor: currentIconColor,
            hoverColor: currentHoverColor,
            onPressed: () async { // 这里的 async/await 是合理的，因为它依赖前一个状态
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
              // isMaximized 状态会通过 listener 更新，这里不需要手动 setState
            },
            tooltip: _isMaximized ? '向下还原' : '最大化',
          ),
          ControlButton(
            icon: Icons.close,
            iconSize: iconSize,
            iconColor: currentIconColor,
            hoverColor: currentCloseHoverColor,
            onPressed: () => windowManager.close(), // 直接调用
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }
}
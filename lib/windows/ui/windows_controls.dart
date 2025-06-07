// lib/windows/ui/windows_controls.dart

/// 该文件定义了 WindowsControls 组件，一个用于桌面窗口的控制按钮组。
/// WindowsControls 包含最小化、最大化/还原和关闭按钮。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/windows/ui/control_button.dart'; // 导入窗口控制按钮组件
import 'package:window_manager/window_manager.dart'; // 导入窗口管理器库

/// `WindowsControls` 类：Windows 窗口控制组件。
///
/// 该组件提供最小化、最大化/还原和关闭窗口的功能按钮。
class WindowsControls extends StatefulWidget {
  final Color? iconColor; // 图标颜色
  final Color? hoverColor; // 悬停颜色
  final Color? closeHoverColor; // 关闭按钮悬停颜色

  /// 构造函数。
  ///
  /// [iconColor]：图标颜色。
  /// [hoverColor]：悬停颜色。
  /// [closeHoverColor]：关闭按钮悬停颜色。
  const WindowsControls({
    super.key,
    this.iconColor,
    this.hoverColor,
    this.closeHoverColor,
  });

  /// 创建状态。
  @override
  State<WindowsControls> createState() => _WindowsControlsState();
}

/// `_WindowsControlsState` 类：`WindowsControls` 的状态管理。
///
/// 管理窗口的最大化状态，并监听窗口事件以更新 UI。
class _WindowsControlsState extends State<WindowsControls> with WindowListener {
  bool _isMaximized = false; // 窗口是否最大化标记
  bool _isInitialized = false; // 初始化标记

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this); // 添加窗口事件监听器
    _initializeMaximizeState(); // 异步获取初始最大化状态
  }

  /// 异步获取初始最大化状态。
  ///
  /// 确保只执行一次。
  Future<void> _initializeMaximizeState() async {
    if (_isInitialized || !mounted) return; // 已初始化或组件未挂载时返回
    _isInitialized = true; // 标记为已尝试初始化

    try {
      final maximized = await windowManager.isMaximized(); // 获取窗口最大化状态
      if (mounted) {
        // 异步操作后再次检查组件是否挂载
        setState(() {
          _isMaximized = maximized; // 更新最大化状态
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMaximized = false; // 发生错误时默认为未最大化
        });
      }
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this); // 移除窗口事件监听器
    super.dispose();
  }

  /// 窗口最大化事件回调。
  @override
  void onWindowMaximize() {
    if (mounted && !_isMaximized) {
      // 状态真正改变时更新
      setState(() => _isMaximized = true);
    }
  }

  /// 窗口取消最大化事件回调。
  @override
  void onWindowUnmaximize() {
    if (mounted && _isMaximized) {
      // 状态真正改变时更新
      setState(() => _isMaximized = false);
    }
  }

  /// 窗口获得焦点事件回调。
  @override
  void onWindowFocus() {}

  /// 窗口失去焦点事件回调。
  @override
  void onWindowBlur() {}

  /// 窗口最小化事件回调。
  @override
  void onWindowMinimize() {}

  /// 窗口恢复事件回调。
  @override
  void onWindowRestore() {}

  /// 窗口尺寸调整事件回调。
  @override
  void onWindowResize() {}

  /// 窗口移动事件回调。
  @override
  void onWindowMove() {}

  /// 窗口进入全屏事件回调。
  @override
  void onWindowEnterFullScreen() {}

  /// 窗口离开全屏事件回调。
  @override
  void onWindowLeaveFullScreen() {}

  /// 构建 Windows 控制按钮组。
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 当前主题

    final Color currentIconColor = widget.iconColor ??
        theme.colorScheme.onSurface.withSafeOpacity(0.8); // 有效图标颜色
    final Color currentHoverColor = widget.hoverColor ??
        theme.colorScheme.onSurface.withSafeOpacity(0.1); // 有效悬停颜色
    final Color currentCloseHoverColor =
        widget.closeHoverColor ?? Colors.red; // 有效关闭按钮悬停颜色

    const double iconSize = 16.0; // 图标大小

    return SizedBox(
      height: double.infinity, // 填充父级高度
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // 主轴末尾对齐
        crossAxisAlignment: CrossAxisAlignment.center, // 交叉轴居中
        children: [
          ControlButton(
            icon: Icons.minimize, // 最小化图标
            iconSize: iconSize, // 图标大小
            iconColor: currentIconColor, // 图标颜色
            hoverColor: currentHoverColor, // 悬停颜色
            onPressed: () => windowManager.minimize(), // 最小化窗口
            tooltip: '最小化', // 提示
          ),
          ControlButton(
            icon: _isMaximized
                ? Icons.filter_none
                : Icons.crop_square, // 根据最大化状态选择图标
            iconSize: iconSize, // 图标大小
            iconColor: currentIconColor, // 图标颜色
            hoverColor: currentHoverColor, // 悬停颜色
            onPressed: () async {
              // 点击回调
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize(); // 取消最大化
              } else {
                await windowManager.maximize(); // 最大化
              }
            },
            tooltip: _isMaximized ? '向下还原' : '最大化', // 提示
          ),
          ControlButton(
            icon: Icons.close, // 关闭图标
            iconSize: iconSize, // 图标大小
            iconColor: currentIconColor, // 图标颜色
            hoverColor: currentCloseHoverColor, // 悬停颜色
            onPressed: () => windowManager.close(), // 关闭窗口
            tooltip: '关闭', // 提示
          ),
        ],
      ),
    );
  }
}

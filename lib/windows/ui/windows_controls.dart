// lib/windows/ui/windows_controls.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/windows/ui/control_button.dart';
import 'package:window_manager/window_manager.dart';

class WindowsControls extends StatefulWidget {
  final Color? iconColor; // 新增：允许外部传入图标颜色
  final Color? hoverColor; // 新增：允许外部传入悬停背景色
  final Color? closeHoverColor; // 新增：允许外部传入关闭悬停背景色

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

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _updateMaximizeState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _updateMaximizeState() async {
    _isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);
  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- 颜色处理 ---
    // 优先使用传入的颜色，否则使用基于主题的默认值
    final Color currentIconColor = widget.iconColor ??
        theme.colorScheme.onSurface.withOpacity(0.8); // 默认用主题反色
    final Color currentHoverColor = widget.hoverColor ??
        theme.colorScheme.onSurface.withOpacity(0.1); // 默认用主题反色的低透明度
    final Color currentCloseHoverColor = widget.closeHoverColor ?? Colors.red;

    const double iconSize = 16.0;

    // 为了确保控件在限定区域内垂直居中，可以使用 Center 或 Padding
    return SizedBox(
      height: double.infinity, // 继承父 Positioned 的高度
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, // 按钮靠右排列
        crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中
        children: [
          ControlButton(
            icon: Icons.minimize,
            iconSize: iconSize,
            iconColor: currentIconColor,
            hoverColor: currentHoverColor,
            onPressed: () async => await windowManager.minimize(),
            tooltip: '最小化',
          ),
          ControlButton(
            icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
            iconSize: iconSize,
            iconColor: currentIconColor,
            hoverColor: currentHoverColor,
            onPressed: () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
            tooltip: _isMaximized ? '向下还原' : '最大化',
          ),
          ControlButton(
            icon: Icons.close,
            iconSize: iconSize,
            iconColor: currentIconColor,
            hoverColor: currentCloseHoverColor, // 关闭按钮特殊处理
            onPressed: () async => await windowManager.close(),
            tooltip: '关闭',
          ),
          // 可以加一点右边距
          // const SizedBox(width: 4),
        ],
      ),
    );
  }
}



// lib/windows/ui/control_button.dart

/// 该文件定义了 ControlButton 组件，一个用于窗口控制的按钮。
/// 该组件用于构建最小化、最大化/恢复和关闭等窗口操作按钮。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件

/// `ControlButton` 类：一个用于窗口控制的按钮组件。
///
/// 该组件提供图标、点击回调、颜色、悬停颜色、图标大小和工具提示。
class ControlButton extends StatelessWidget {
  final IconData icon; // 按钮图标
  final VoidCallback onPressed; // 按钮点击回调
  final Color iconColor; // 图标颜色
  final Color hoverColor; // 悬停颜色
  final double iconSize; // 图标大小
  final String tooltip; // 工具提示文本

  /// 构造函数。
  ///
  /// [icon]：图标。
  /// [onPressed]：点击回调。
  /// [iconColor]：图标颜色。
  /// [hoverColor]：悬停颜色。
  /// [iconSize]：图标大小。
  /// [tooltip]：工具提示。
  const ControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.iconColor,
    required this.hoverColor,
    required this.iconSize,
    required this.tooltip,
  });

  /// 构建窗口控制按钮。
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip, // 提示文本
      waitDuration: const Duration(milliseconds: 500), // 等待时长
      child: InkWell(
        onTap: onPressed, // 点击回调
        hoverColor: hoverColor, // 悬停颜色
        child: Container(
          width: 45, // 宽度
          height: double.infinity, // 填充父级高度
          alignment: Alignment.center, // 内容居中
          child: Icon(
            icon, // 图标
            color: iconColor, // 图标颜色
            size: iconSize, // 图标大小
          ),
        ),
      ),
    );
  }
}

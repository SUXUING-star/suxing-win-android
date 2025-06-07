// lib/widgets/ui/buttons/warning_button.dart

/// 该文件定义了 WarningButton 组件，一个用于显示警告或危险操作的按钮。
/// WarningButton 采用警告色调，支持图标、加载状态和禁用状态。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件

/// `WarningButton` 类：一个用于显示警告或危险操作的按钮组件。
///
/// 该组件采用警告色调，支持图标、加载状态和禁用状态。
class WarningButton extends StatelessWidget {
  final VoidCallback onPressed; // 按钮按下时触发的回调
  final String label; // 按钮文本
  final IconData icon; // 按钮图标
  final double iconSize; // 图标大小
  final double fontSize; // 字体大小
  final EdgeInsetsGeometry padding; // 按钮内边距
  final bool isLoading; // 按钮是否处于加载状态
  final bool isEnabled; // 按钮是否可用

  /// 构造函数。
  ///
  /// [onPressed]：点击回调。
  /// [label]：文本。
  /// [icon]：图标。
  /// [iconSize]：图标大小。
  /// [fontSize]：字体大小。
  /// [padding]：内边距。
  /// [isLoading]：是否加载中。
  /// [isEnabled]：是否可用。
  const WarningButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.iconSize = 18.0,
    this.fontSize = 15.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.isLoading = false,
    this.isEnabled = true,
  });

  /// 构建警告按钮。
  ///
  /// 该方法根据按钮状态和属性生成不同的按钮内容和样式。
  @override
  Widget build(BuildContext context) {
    final Color warningColor = Colors.red.shade600; // 警告色
    final int backgroundAlpha = (255 * 0.15).round(); // 背景透明度
    final Color buttonBackgroundColor =
        warningColor.withAlpha(backgroundAlpha); // 按钮背景色
    final Color buttonForegroundColor = warningColor; // 按钮前景色

    final Color disabledBackgroundColor =
        Colors.grey.shade200.withAlpha(150); // 禁用状态背景色
    final Color disabledForegroundColor = Colors.grey.shade400; // 禁用状态前景色

    return ElevatedButton.icon(
      onPressed: isEnabled && !isLoading ? onPressed : null, // 点击回调
      icon: isLoading // 根据加载状态选择图标或进度指示器
          ? SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2, // 粗细
                color: buttonForegroundColor, // 颜色
              ),
            )
          : Icon(
              icon, // 图标
              size: iconSize, // 大小
              color: isEnabled
                  ? buttonForegroundColor
                  : disabledForegroundColor, // 颜色
            ),
      label: AppText(
        label, // 文本
        style: TextStyle(
          fontSize: fontSize, // 字号
          color:
              isEnabled ? buttonForegroundColor : disabledForegroundColor, // 颜色
          fontWeight: FontWeight.w600, // 字重
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isEnabled ? buttonBackgroundColor : disabledBackgroundColor, // 背景色
        foregroundColor: buttonForegroundColor, // 前景色
        disabledForegroundColor: disabledForegroundColor, // 禁用时前景色
        disabledBackgroundColor: disabledBackgroundColor, // 禁用时背景色
        elevation: 0, // 阴影高度
        padding: padding, // 内边距
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 圆角
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 点击区域尺寸
      ),
    );
  }
}

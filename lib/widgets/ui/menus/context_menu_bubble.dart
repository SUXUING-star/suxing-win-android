// lib/widgets/ui/menus/context_menu_bubble.dart
import 'package:flutter/material.dart';
import '../text/app_text.dart';     // 导入你的 AppText
import '../text/app_text_type.dart'; // 导入你的 AppTextType

class ContextMenuBubble extends StatelessWidget {
  // 接收 标签 -> 回调 的 Map
  final Map<String, VoidCallback?> actions;
  // 可以添加更多自定义选项，比如背景色、文字颜色、字体大小等
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final double borderRadius;
  final double elevation;

  const ContextMenuBubble({
    super.key,
    required this.actions,
    this.backgroundColor = const Color(0xE6333333), // 深灰色半透明 (0xE6 = 90% alpha)
    this.textColor = Colors.white,
    this.fontSize = 14.0,
    this.borderRadius = 10.0,
    this.elevation = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> menuButtons = [];

    // 遍历 actions 构建按钮列表
    actions.forEach((label, onPressed) {
      // 在非第一个按钮前添加分隔符
      if (menuButtons.isNotEmpty) {
        menuButtons.add(
          Container(
            height: 18, // 分隔符高度
            width: 1,
            color: textColor.withOpacity(0.2), // 使用文字颜色的透明色
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
          ),
        );
      }

      menuButtons.add(
        // 使用 InkWell 实现点击效果
        InkWell(
          onTap: onPressed, // 直接调用传入的回调 (外部处理关闭)
          borderRadius: BorderRadius.circular(4), // 点击效果圆角
          // 使用 Material 控制水波纹颜色（可选）
          // splashColor: textColor.withOpacity(0.1),
          // highlightColor: textColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // 按钮内边距
            // 使用 AppText 显示标签
            child: AppText(
              label,
              type: AppTextType.body, // 可以根据需要调整类型
              color: textColor,       // 使用传入的文字颜色
              fontSize: fontSize,     // 使用传入的字体大小
            ),
          ),
        ),
      );
    });

    // 如果没有按钮，返回空 SizedBox
    if (menuButtons.isEmpty) {
      return const SizedBox.shrink();
    }

    // 使用 Card 作为气泡容器
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      color: backgroundColor,
      margin: EdgeInsets.zero, // 移除 Card 默认 margin
      clipBehavior: Clip.antiAlias, // 裁剪内容
      child: Row(
        mainAxisSize: MainAxisSize.min, // 让 Row 和 Card 包裹内容
        children: menuButtons,
      ),
    );
  }
}
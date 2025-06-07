// lib/widgets/ui/menus/context_menu_bubble.dart

/// 该文件定义了 ContextMenuBubble 组件，一个自定义的上下文菜单气泡。
/// ContextMenuBubble 用于显示一系列可点击的操作按钮。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart'; // 导入应用文本类型

/// `ContextMenuBubble` 类：自定义上下文菜单气泡组件。
///
/// 该组件显示一个水平排列的可点击操作按钮集合。
class ContextMenuBubble extends StatelessWidget {
  final Map<String, VoidCallback?> actions; // 接收标签到回调的映射，定义菜单中的操作
  final Color backgroundColor; // 菜单气泡的背景颜色
  final Color textColor; // 菜单项文本的颜色
  final double fontSize; // 菜单项文本的字体大小
  final double borderRadius; // 菜单气泡的圆角半径
  final double elevation; // 菜单气泡的阴影高度

  /// 构造函数。
  ///
  /// [actions]：操作映射。
  /// [backgroundColor]：背景颜色。
  /// [textColor]：文本颜色。
  /// [fontSize]：字体大小。
  /// [borderRadius]：圆角半径。
  /// [elevation]：阴影高度。
  const ContextMenuBubble({
    super.key,
    required this.actions,
    this.backgroundColor = const Color(0xE6333333), // 深灰色半透明
    this.textColor = Colors.white,
    this.fontSize = 14.0,
    this.borderRadius = 10.0,
    this.elevation = 4.0,
  });

  /// 构建上下文菜单气泡。
  ///
  /// 该方法根据 `actions` 映射创建一系列可点击的菜单按钮，并以水平气泡形式展示。
  @override
  Widget build(BuildContext context) {
    final List<Widget> menuButtons = []; // 存储菜单按钮列表

    actions.forEach((label, onPressed) {
      if (menuButtons.isNotEmpty) {
        // 在非第一个按钮前添加分隔符
        menuButtons.add(
          Container(
            height: 18, // 分隔符高度
            width: 1, // 分隔符宽度
            color: textColor.withSafeOpacity(0.2), // 分隔符颜色
            margin: const EdgeInsets.symmetric(horizontal: 4.0), // 分隔符外边距
          ),
        );
      }

      menuButtons.add(
        InkWell(
          onTap: onPressed, // 点击回调
          borderRadius: BorderRadius.circular(4), // 点击效果圆角
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12.0, vertical: 8.0), // 按钮内边距
            child: AppText(
              label, // 标签文本
              type: AppTextType.body, // 文本类型
              color: textColor, // 文本颜色
              fontSize: fontSize, // 字体大小
            ),
          ),
        ),
      );
    });

    if (menuButtons.isEmpty) {
      // 如果没有按钮，返回一个空组件
      return const SizedBox.shrink();
    }

    return Card(
      elevation: elevation, // 阴影高度
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius), // 圆角
      ),
      color: backgroundColor, // 背景颜色
      margin: EdgeInsets.zero, // 移除 Card 默认外边距
      clipBehavior: Clip.antiAlias, // 裁剪内容
      child: Row(
        mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化以适应内容
        children: menuButtons, // 菜单按钮列表
      ),
    );
  }
}

// lib/widgets/components/screen/game/card/game_stat_item_widget.dart

/// 该文件定义了 StatItemWidget 组件，一个用于显示游戏统计项的 StatelessWidget。
/// StatItemWidget 展示图标和数值，并根据 `showBackground` 参数调整样式。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具

/// `StatItemWidget` 类：显示游戏统计项的组件。
///
/// 该组件展示图标和数值，并根据是否显示背景来调整其布局和颜色。
class StatItemWidget extends StatelessWidget {
  final IconData icon; // 统计项图标
  final String value; // 统计项数值
  final Color color; // 图标和部分文本的颜色
  final double iconSize; // 图标大小
  final double fontSize; // 字体大小
  final bool showBackground; // 是否显示背景装饰

  /// 构造函数。
  ///
  /// [icon]：图标。
  /// [value]：数值。
  /// [color]：颜色。
  /// [iconSize]：图标大小。
  /// [fontSize]：字体大小。
  /// [showBackground]：是否显示背景。
  const StatItemWidget({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    required this.iconSize,
    required this.fontSize,
    required this.showBackground,
  });

  /// 构建统计项组件。
  ///
  /// 根据 `showBackground` 参数选择网格布局或列表布局样式。
  @override
  Widget build(BuildContext context) {
    if (showBackground) {
      // 网格布局中的显示样式
      return Row(
        mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
        children: [
          Container(
            padding: const EdgeInsets.all(3), // 内边距
            decoration: BoxDecoration(
              color: color.withSafeOpacity(0.2), // 背景色
              shape: BoxShape.circle, // 形状为圆形
            ),
            child: Icon(
              icon, // 图标
              size: iconSize, // 大小
              color: color, // 颜色
            ),
          ),
          const SizedBox(width: 4), // 间距
          Text(
            value, // 数值文本
            style: TextStyle(
              fontSize: fontSize, // 字号
              color: Colors.grey.shade800, // 颜色
              fontWeight: FontWeight.bold, // 字重
            ),
          ),
        ],
      );
    } else {
      // 列表布局中的显示样式
      return Row(
        mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
        children: [
          Container(
            padding: const EdgeInsets.all(2), // 内边距
            decoration: BoxDecoration(
              color: color.withSafeOpacity(0.15), // 背景色
              shape: BoxShape.circle, // 形状为圆形
            ),
            child: Icon(
              icon, // 图标
              size: iconSize, // 大小
              color: color, // 颜色
            ),
          ),
          const SizedBox(width: 4), // 间距
          Text(
            value, // 数值文本
            style: TextStyle(
              fontSize: fontSize, // 字号
              color: Colors.grey[700], // 颜色
              fontWeight: FontWeight.w500, // 字重
            ),
          ),
        ],
      );
    }
  }
}

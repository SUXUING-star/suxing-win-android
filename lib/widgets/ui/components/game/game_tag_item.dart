// lib/widgets/ui/components/game/game_tag_item.dart

/// 该文件定义了 GameTagItem 组件，一个用于显示游戏标签的 StatelessWidget。
/// GameTagItem 根据标签是否选中调整其背景、文本和边框样式。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/constants/game/game_constants.dart'; // 导入游戏常量
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具

/// `GameTagItem` 类：显示游戏标签的组件。
///
/// 该组件根据标签是否选中，显示不同的背景、文本和边框样式。
class GameTagItem extends StatelessWidget {
  final String tag; // 标签文本
  final int? count; // 标签关联的数量
  final bool isSelected; // 标签是否选中

  static const double tagBorderRadius = 12.0; // 标签圆角半径
  static const double tagHorizontalPadding = 8.0; // 标签水平内边距
  static const double tagVerticalPadding = 4.0; // 标签垂直内边距
  static const double tagFontSize = 11.0; // 标签字体大小
  static const double tagCountFontSize = 9.0; // 标签数量字体大小

  /// 构造函数。
  ///
  /// [tag]：标签。
  /// [count]：数量。
  /// [isSelected]：是否选中。
  const GameTagItem({
    super.key,
    required this.tag,
    this.count,
    this.isSelected = false,
  });

  /// 构建游戏标签项。
  @override
  Widget build(BuildContext context) {
    final Color baseTagColor = GameTagUtils.getTagColor(tag); // 获取基础标签颜色

    final Color finalBgColor; // 最终背景色
    final Color finalTextColor; // 最终文本颜色
    final FontWeight finalFontWeight; // 最终字体粗细
    final Border? finalBorder; // 最终边框

    if (isSelected) {
      // 选中状态
      finalBgColor = baseTagColor; // 彩色背景
      finalTextColor =
          GameTagUtils.getTextColorForBackground(baseTagColor); // 高对比度文本颜色
      finalFontWeight = FontWeight.bold; // 粗体
      finalBorder = null; // 无边框
    } else {
      // 未选中状态
      finalBgColor = baseTagColor.withSafeOpacity(0.1); // 淡彩背景
      finalTextColor = baseTagColor; // 彩色文本
      finalFontWeight = FontWeight.normal; // 普通字体
      finalBorder = Border.all(
        color: baseTagColor.withSafeOpacity(0.5), // 彩色边框
        width: 1.0, // 边框宽度
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: tagHorizontalPadding,
          vertical: tagVerticalPadding), // 内边距
      decoration: BoxDecoration(
        color: finalBgColor, // 背景色
        borderRadius: BorderRadius.circular(tagBorderRadius), // 圆角
        border: finalBorder, // 边框
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化
        children: [
          Flexible(
            child: Text(
              tag, // 标签文本
              style: TextStyle(
                color: finalTextColor, // 颜色
                fontWeight: finalFontWeight, // 字重
                fontSize: tagFontSize, // 字号
              ),
              overflow: TextOverflow.ellipsis, // 溢出显示省略号
              maxLines: 1, // 最大行数
            ),
          ),
          if (count != null) ...[
            // 数量非空时显示数量
            const SizedBox(width: 5), // 间距
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1), // 内边距
              decoration: BoxDecoration(
                color: finalTextColor
                    .withSafeOpacity(isSelected ? 0.2 : 0.15), // 背景色
                borderRadius: BorderRadius.circular(6), // 圆角
              ),
              child: Text(
                count.toString(), // 数量文本
                style: TextStyle(
                  color: finalTextColor, // 颜色
                  fontWeight: FontWeight.bold, // 字重
                  fontSize: tagCountFontSize, // 字号
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

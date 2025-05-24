// lib/widgets/ui/components/game/game_tag.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class GameTag extends StatelessWidget {
  final String tag;
  final int? count;
  final bool isSelected;

  // 统一样式参数 (可以微调)
  static const double tagBorderRadius = 12.0;
  static const double tagHorizontalPadding = 8.0;
  static const double tagVerticalPadding = 4.0;
  static const double tagFontSize = 11.0;
  static const double tagCountFontSize = 9.0;

  const GameTag({
    super.key,
    required this.tag,
    this.count,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseTagColor = GameTagUtils.getTagColor(tag);

    // 2. 根据 isSelected 确定最终的样式
    final Color finalBgColor;
    final Color finalTextColor;
    final FontWeight finalFontWeight;
    final Border? finalBorder;

    if (isSelected) {
      // --- 选中状态：彩色背景，高对比度文字，无边框 ---
      finalBgColor = baseTagColor;
      finalTextColor =
          GameTagUtils.getTextColorForBackground(baseTagColor); // 黑或白
      finalFontWeight = FontWeight.bold;
      finalBorder = null;
    } else {
      // --- 未选中状态：新尝试！淡彩背景 + 彩色边框 + 彩色文字 ---
      finalBgColor = baseTagColor.withSafeOpacity(0.1);
      finalTextColor = baseTagColor; // <--- 彩色文字
      finalFontWeight = FontWeight.normal;
      // **关键：添加一个比背景色深一点的彩色边框**
      finalBorder = Border.all(
        color: baseTagColor.withSafeOpacity(0.5),
        width: 1.0, // <--- 边框细一点
      );
    }

    // 4. 构建 Widget
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: tagHorizontalPadding, vertical: tagVerticalPadding),
      decoration: BoxDecoration(
        color: finalBgColor,
        borderRadius: BorderRadius.circular(tagBorderRadius),
        border: finalBorder, // 应用边框
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 使用 Flexible 保证长文本不溢出
          Flexible(
            child: Text(
              tag,
              style: TextStyle(
                color: finalTextColor,
                fontWeight: finalFontWeight,
                fontSize: tagFontSize,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (count != null) ...[
            SizedBox(width: 5), // 间距
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                // 计数的背景：用文字颜色的更淡透明度
                color: finalTextColor.withSafeOpacity(
                    isSelected ? 0.2 : 0.15), // 未选中时计数背景透明度也调一下
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: finalTextColor,
                  fontWeight: FontWeight.bold, // 计数恒定加粗
                  fontSize: tagCountFontSize,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

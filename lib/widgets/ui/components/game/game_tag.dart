// lib/widgets/ui/components/game/game_tag.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/game/game_constants.dart'; // <--- 用回这个！

class GameTag extends StatelessWidget {
  final String tag;
  final int? count;
  final bool isSelected;

  const GameTag({
    super.key,
    required this.tag,
    this.count,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 获取基础标签颜色 (用回 GameTagUtils!)
    final Color baseTagColor = GameTagUtils.getTagColor(tag);

    // 2. 根据 isSelected 确定最终的样式
    final Color finalBgColor;
    final Color finalTextColor;
    final FontWeight finalFontWeight;
    final Border? finalBorder;

    if (isSelected) {
      // --- 选中状态：彩色背景，高对比度文字，无边框 ---
      finalBgColor = baseTagColor;
      finalTextColor = GameTagUtils.getTextColorForBackground(baseTagColor); // 黑或白
      finalFontWeight = FontWeight.bold;
      finalBorder = null;
    } else {
      // --- 未选中状态：新尝试！淡彩背景 + 彩色边框 + 彩色文字 ---
      finalBgColor = baseTagColor.withOpacity(0.1); // <--- 非常淡的彩色背景
      finalTextColor = baseTagColor;                 // <--- 彩色文字
      finalFontWeight = FontWeight.normal;
      // **关键：添加一个比背景色深一点的彩色边框**
      finalBorder = Border.all(
        color: baseTagColor.withOpacity(0.5), // <--- 用半透明的基础色做边框
        width: 1.0,                          // <--- 边框细一点
      );
    }

    // 3. 统一样式参数 (可以微调)
    final double borderRadius = 12.0; // 圆角大一点试试？
    final double horizontalPadding = 8.0;
    final double verticalPadding = 4.0;
    final double fontSize = 11.0; // 字号稍微调整
    final double countFontSize = 9.0;

    // 4. 构建 Widget
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: finalBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
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
                fontSize: fontSize,
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
                color: finalTextColor.withOpacity(isSelected ? 0.2 : 0.15), // 未选中时计数背景透明度也调一下
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: finalTextColor,
                  fontWeight: FontWeight.bold, // 计数恒定加粗
                  fontSize: countFontSize,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
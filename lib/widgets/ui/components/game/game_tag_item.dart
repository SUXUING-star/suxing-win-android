// lib/widgets/ui/components/game/game_tag_item.dart
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/widgets/ui/components/base_tag_view.dart';

/// `GameTagItem` 类：显示游戏标签的组件，支持选中和未选中两种状态。
///
/// 未选中时，它使用统一的 `BaseTagView` 来渲染磨砂质感。
/// 选中时，它渲染一个实心背景的样式。
class GameTagItem extends StatelessWidget {
  final String tag;
  final int? count;
  final bool isSelected;

  const GameTagItem({
    super.key,
    required this.tag,
    this.count,
    this.isSelected = false,
  });



  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      // --- 选中状态：使用原来的实心样式，逻辑保留在此处 ---
      final baseColor = GameTagUtils.getTagColor(tag);
      final textColor = GameTagUtils.getTextColorForBackground(baseColor);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(BaseTagView.tagRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                tag,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.0,
                  ),
                ),
              ),
            ]
          ],
        ),
      );
    } else {
      // --- 未选中状态：直接使用纯净的 BaseTagView ---
      return BaseTagView(
        text: tag,
        baseColor: GameTagUtils.getTagColor(tag),
        count: count,
        isMini: true, // GameTagItem 总是 mini 模式
      );
    }
  }
}
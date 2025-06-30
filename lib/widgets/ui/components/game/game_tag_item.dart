// lib/widgets/ui/components/game/game_tag_item.dart
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/game/game/enrich_game_tag.dart';
import 'package:suxingchahui/widgets/ui/components/base_tag_view.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

/// `GameTagItem` 类：显示游戏标签的组件，支持选中和未选中两种状态。
///
/// 未选中时，它使用统一的 `BaseTagView` 来渲染磨砂质感。
/// 选中时，它渲染一个实心背景的样式。
class GameTagItem extends StatelessWidget {
  final EnrichGameTag enrichTag;
  final int? count;
  final bool isSelected;

  const GameTagItem({
    super.key,
    required this.enrichTag,
    this.count,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // --- 选中状态：使用原来的实心样式，逻辑保留在此处 ---
    final baseColor = enrichTag.backgroundColor;
    final textColor = enrichTag.textColor;
    final tagLabel = enrichTag.tag;
    if (isSelected) {
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
                tagLabel,
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
                  color: textColor.withSafeOpacity(0.2),
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
        text: tagLabel,
        baseColor: baseColor,
        count: count,
        isMini: true, // GameTagItem 总是 mini 模式
      );
    }
  }
}

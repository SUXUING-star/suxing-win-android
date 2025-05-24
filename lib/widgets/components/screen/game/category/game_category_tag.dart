// lib/widgets/components/screnn/game/category/game_category_tag.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/components/game/game_category_tag_view.dart';

class GameCategoryTag extends StatelessWidget {
  final String category;
  final bool isMini;
  final bool needOnClick;
  final Function(BuildContext context, String category)?
      onClickFilterGameCategory;

  const GameCategoryTag({
    super.key,
    required this.category,
    this.onClickFilterGameCategory,
    this.isMini = true,
    this.needOnClick = false,
  });

  @override
  Widget build(BuildContext context) {
    // 使用 GameCategoryTagView 来展示 UI
    Widget tagView = GameCategoryTagView(
      category: category,
      isMini: isMini,
    );

    if (!needOnClick || onClickFilterGameCategory == null) {
      // 如果不需要点击，直接返回纯 UI 组件
      return tagView;
    }

    // 如果需要点击，则包裹 InkWell
    // 获取与 GameCategoryTagView 一致的圆角半径
    final double inkWellRadius = GameCategoryTagView.getRadius(isMini);

    return InkWell(
      onTap: () => onClickFilterGameCategory!(context, category),
      borderRadius: BorderRadius.circular(inkWellRadius),
      child: tagView, // 内部是纯 UI 组件
    );
  }
}

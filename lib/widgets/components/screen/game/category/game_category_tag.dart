// lib/widgets/components/screen/game/category/game_category_tag.dart

/// 该文件定义了 GameCategoryTag 组件，一个可点击的游戏分类标签。
/// GameCategoryTag 用于展示游戏分类，并支持点击筛选。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/components/game/game_category_tag_view.dart'; // 导入游戏分类标签视图

/// `GameCategoryTag` 类：可点击的游戏分类标签组件。
///
/// 该组件展示游戏分类，并根据配置支持点击筛选功能。
class GameCategoryTag extends StatelessWidget {
  final String category; // 游戏分类
  final bool isMini; // 是否为迷你模式
  final bool needOnClick; // 是否需要点击功能
  final Function(BuildContext context, String category)?
      onClickFilterGameCategory; // 点击筛选游戏分类的回调

  /// 构造函数。
  ///
  /// [category]：分类。
  /// [onClickFilterGameCategory]：点击筛选回调。
  /// [isMini]：是否迷你模式。
  /// [needOnClick]：是否需要点击。
  const GameCategoryTag({
    super.key,
    required this.category,
    this.onClickFilterGameCategory,
    this.isMini = true,
    this.needOnClick = false,
  });

  /// 构建游戏分类标签。
  ///
  /// 如果不需要点击功能或未提供点击回调，则直接返回纯 UI 组件。
  /// 否则，包裹 [InkWell] 以实现点击效果。
  @override
  Widget build(BuildContext context) {
    Widget tagView = GameCategoryTagView(
      category: category, // 分类
      isMini: isMini, // 是否迷你模式
    );

    if (!needOnClick || onClickFilterGameCategory == null) {
      // 如果不需要点击或无点击回调
      return tagView; // 直接返回标签视图
    }

    final double inkWellRadius =
        GameCategoryTagView.getRadius(isMini); // 获取圆角半径

    return InkWell(
      onTap: () => onClickFilterGameCategory!(context, category), // 点击回调
      borderRadius: BorderRadius.circular(inkWellRadius), // 圆角
      child: tagView, // 标签视图
    );
  }
}

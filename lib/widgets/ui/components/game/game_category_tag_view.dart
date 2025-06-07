// lib/widgets/ui/components/game/game_category_tag_view.dart

/// 该文件定义了 GameCategoryTagView 组件，一个用于显示游戏分类标签的 StatelessWidget。
/// GameCategoryTagView 根据分类名称和迷你模式调整标签的样式。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/constants/game/game_constants.dart'; // 导入游戏常量

/// `GameCategoryTagView` 类：显示游戏分类标签的组件。
///
/// 该组件根据分类名称和是否为迷你模式调整标签的内边距、字体大小和圆角。
class GameCategoryTagView extends StatelessWidget {
  final String category; // 游戏分类名称
  final bool isMini; // 是否为迷你模式

  /// 构造函数。
  ///
  /// [category]：分类名称。
  /// [isMini]：是否迷你模式。
  const GameCategoryTagView({
    super.key,
    required this.category,
    this.isMini = true,
  });

  /// 获取圆角半径。
  ///
  /// [isMini]：是否为迷你模式。
  /// 返回根据模式计算的圆角半径。
  static double getRadius(bool isMini) {
    return isMini ? 8.0 : 20.0;
  }

  /// 构建游戏分类标签视图。
  @override
  Widget build(BuildContext context) {
    final double horizontal = isMini ? 6 : 12; // 水平内边距
    final double vertical = isMini ? 2 : 6; // 垂直内边距
    final double fontSize = isMini ? 10 : 14; // 字体大小
    final double currentRadius = getRadius(isMini); // 当前圆角半径

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: horizontal, vertical: vertical), // 内边距
      decoration: BoxDecoration(
        color: GameCategoryUtils.getCategoryColor(category), // 背景色
        borderRadius: BorderRadius.circular(currentRadius), // 圆角
      ),
      child: Text(
        category, // 分类文本
        style: TextStyle(
          color: Colors.white, // 颜色
          fontSize: fontSize, // 字号
          fontWeight: FontWeight.bold, // 字重
        ),
        overflow: TextOverflow.ellipsis, // 溢出显示省略号
        maxLines: 1, // 最大行数
      ),
    );
  }
}

// lib/models/game/game/enrich_game_category.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/preset/simple_color_theme.dart';
import 'package:suxingchahui/models/utils/util_json.dart';

class EnrichGameCategory implements SimpleColorThemeExtension {
  /// 汉化分类常量。
  static const String translated = '汉化';

  /// 生肉分类常量。
  static const String original = '生肉';

  /// 默认游戏分类列表。
  static const List<String> defaultGameCategory = [original, translated];

  static const String categoryAll = '全部';

  final String category;

  const EnrichGameCategory({
    required this.category,
  });

  static const EnrichGameCategory enrichOriginal =
      EnrichGameCategory(category: original);
  static const EnrichGameCategory enrichTranslated =
      EnrichGameCategory(category: translated);
  static const defaultEnrichGameCategory = [
    enrichOriginal,
    enrichTranslated,
  ];

  @override
  Color getTextColor() {
    final color = getCategoryBackgroundColor(category);
    return getCategoryTextColorForBackground(color);
  }

  @override
  Color getBackgroundColor() {
    return getCategoryBackgroundColor(category);
  }

  @override
  String getTextLabel() {
    return category;
  }

  /// 根据分类字符串获取对应的颜色。
  ///
  /// [category] ：分类字符串。
  /// 返回对应的颜色。
  static Color getCategoryBackgroundColor(String category) {
    switch (category) {
      case (translated):
        return Colors.blue.shade300;
      case (original):
        return Colors.green.shade300;
      default:
        return Colors.grey.shade200;
    }
  }

  factory EnrichGameCategory.fromCategory(String category) {
    return EnrichGameCategory(
      category: category,
    );
  }

  /// 根据背景颜色计算合适的文本颜色。
  ///
  /// [backgroundColor]：背景颜色。
  /// 返回白色。
  static Color getCategoryTextColorForBackground(Color color) {
    return Colors.white; // 返回白色
  }

  static List<EnrichGameCategory> fromCategories(List<String> list) =>
      UtilJson.fromListStringToListObject(
        list,
        (c) => EnrichGameCategory.fromCategory(c),
      ).toList();
}

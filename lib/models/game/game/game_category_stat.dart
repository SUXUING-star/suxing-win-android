// lib/models/game/game/game_category_stat.dart



import 'package:flutter/painting.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/preset/simple_color_theme.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';
import 'package:suxingchahui/models/game/game/enrich_game_category.dart';

class GameCategoryStat implements SimpleColorThemeExtension {
  final String category;
  final int count;

  GameCategoryStat({
    required this.category,
    required this.count,
  });

  @override
  Color getBackgroundColor() => enrichCategory.backgroundColor;

  @override
  Color getTextColor() => enrichCategory.textColor;

  @override
  String getTextLabel() => enrichCategory.textLabel;
}

extension GameCategoryStatExtension on GameCategoryStat {
  EnrichGameCategory get enrichCategory =>
      EnrichGameCategory.fromCategory(category);
}

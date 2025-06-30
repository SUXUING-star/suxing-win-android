// lib/widgets/ui/components/game/game_category_tag_view.dart
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/game/game/enrich_game_category.dart';
import 'package:suxingchahui/widgets/ui/components/base_tag_view.dart';

class GameCategoryTagView extends StatelessWidget {
  final EnrichGameCategory enrichCategory;
  final bool isMini;
  final bool isFrosted;

  const GameCategoryTagView({
    super.key,
    required this.enrichCategory,
    this.isMini = true,
    this.isFrosted = true,
  });

  @override
  Widget build(BuildContext context) {
    return BaseTagView(
      text: enrichCategory.category,
      baseColor: enrichCategory.textColor,
      isMini: isMini,
      isFrosted: isFrosted,
    );
  }
}

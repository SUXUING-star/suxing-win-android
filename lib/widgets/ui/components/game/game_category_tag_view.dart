// lib/widgets/ui/components/game/game_category_tag_view.dart
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'package:suxingchahui/widgets/ui/components/base_tag_view.dart';

class GameCategoryTagView extends StatelessWidget {
  final String category;
  final bool isMini;
  final bool isFrosted;

  const GameCategoryTagView({
    super.key,
    required this.category,
    this.isMini = true,
    this.isFrosted = true,
  });

  @override
  Widget build(BuildContext context) {
    return BaseTagView(
      text: category,
      baseColor: GameCategoryUtils.getCategoryColor(category),
      isMini: isMini,
      isFrosted: isFrosted,
    );
  }
}
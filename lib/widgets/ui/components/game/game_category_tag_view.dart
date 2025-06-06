// lib/widgets/ui/components/game/game_category_tag_view.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';

class GameCategoryTagView extends StatelessWidget {
  final String category;
  final bool isMini;

  const GameCategoryTagView({
    super.key,
    required this.category,
    this.isMini = true,
  });

  // Helper to calculate radius, so it's consistent
  static double getRadius(bool isMini) {
    return isMini ? 8.0 : 20.0;
  }

  @override
  Widget build(BuildContext context) {
    final double horizontal = isMini ? 6 : 12;
    final double vertical = isMini ? 2 : 6;
    final double fontSize = isMini ? 10 : 14;
    final double currentRadius = getRadius(isMini);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: GameCategoryUtils.getCategoryColor(category),
        borderRadius: BorderRadius.circular(currentRadius),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

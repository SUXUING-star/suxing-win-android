import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';

class GameCategoryTag extends StatelessWidget {
  final String category;
  final bool isMini;

  const GameCategoryTag({
    super.key,
    required this.category,
    this.isMini = true,
  });
  @override
  Widget build(BuildContext context) {
    final double horizontal = isMini ? 6 : 12;
    final double vertical = isMini ? 2 : 6;
    final double fontSize = isMini ? 10 : 14;
    final double radius = isMini ? 8 : 20;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: GameCategoryUtils.getCategoryColor(category),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

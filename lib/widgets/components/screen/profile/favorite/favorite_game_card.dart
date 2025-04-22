// lib/widgets/components/screen/game/favorite/favorite_game_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/components/common_game_card.dart';

/// 为游戏收藏屏幕专门设计的卡片组件
class FavoriteGameCard extends CommonGameCard {
  final VoidCallback? onFavoritePressed;

  const FavoriteGameCard({
    super.key,
    required super.game,
    super.isGridItem = false,
    this.onFavoritePressed,
  });

  Widget _buildListTopRightAction(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.favorite,
        color: Colors.red,
        size: 18,
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(),
      onPressed: onFavoritePressed,
    );
  }

  Widget _buildGridTopRightAction(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.favorite,
        color: Colors.red,
        size: 24,
      ),
      onPressed: onFavoritePressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.7),
        padding: EdgeInsets.all(8),
      ),
    );
  }
}
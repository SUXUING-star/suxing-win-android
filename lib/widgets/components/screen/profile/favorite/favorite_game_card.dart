// lib/widgets/components/screen/game/favorite/favorite_game_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/components/common_game_card.dart';
import '../../../../../models/game/game.dart';

/// 为游戏收藏屏幕专门设计的卡片组件
class FavoriteGameCard extends CommonGameCard {
  final VoidCallback? onFavoritePressed;

  const FavoriteGameCard({
    Key? key,
    required Game game,
    bool isGridItem = false,
    this.onFavoritePressed,
  }) : super(
    key: key,
    game: game,
    isGridItem: isGridItem,
  );

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
// lib/widgets/components/screen/game/favorite/favorite_game_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart';

/// 为游戏收藏屏幕专门设计的卡片组件
class FavoriteGameCard extends CommonGameCard {
  final VoidCallback? onFavoritePressed;

  const FavoriteGameCard({
    super.key,
    required super.game,
    super.isGridItem = false,
    this.onFavoritePressed,
  });
}
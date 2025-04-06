// lib/widgets/components/screen/game/collection/card/collection_game_card.dart
import 'package:flutter/material.dart';
import '../../../../../../models/game/game.dart';
import '../../../../ui/components/common_game_card.dart';

/// 为游戏收藏屏幕专门设计的卡片组件
class CollectionGameCard extends CommonGameCard {
  final String? collectionStatus; // 收藏状态: want_to_play, playing, played

  const CollectionGameCard({
    Key? key,
    required Game game,
    this.collectionStatus,
    bool isGridItem = false,
  }) : super(
    key: key,
    game: game,
    isGridItem: isGridItem,
  );




  // 收藏状态图标
  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'want_to_play':
        icon = Icons.star_border;
        color = Colors.blue;
        break;
      case 'playing':
        icon = Icons.videogame_asset;
        color = Colors.green;
        break;
      case 'played':
        icon = Icons.check_circle;
        color = Colors.purple;
        break;
      default:
        icon = Icons.bookmark;
        color = Colors.grey;
    }

    return Icon(icon, size: 16, color: color);
  }
}
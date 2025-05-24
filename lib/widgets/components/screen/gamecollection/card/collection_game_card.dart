// lib/widgets/components/screen/game/collection/card/collection_game_card.dart

import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart';

/// 为游戏收藏屏幕专门设计的卡片组件
class CollectionGameCard extends CommonGameCard {
  final String? collectionStatus; // 收藏状态: want_to_play, playing, played

  const CollectionGameCard({
    super.key,
    required super.game,
    this.collectionStatus,
    super.isGridItem = false,
  });
}

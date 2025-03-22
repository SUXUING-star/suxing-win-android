// lib/widgets/components/screen/profile/open/mobile/profile_game_card.dart
import 'package:flutter/material.dart';
import '../../../../../../models/game/game.dart';
import '../../../common/card/base_game_card.dart';

class ProfileGameCard extends BaseGameCard {
  // 简单继承基类，不需要添加额外的操作按钮
  const ProfileGameCard({
    Key? key,
    required Game game,
    bool isGridItem = false,
  }) : super(
    key: key,
    game: game,
    isGridItem: isGridItem,
  );

// ProfileGameCard不需要重写顶部右侧操作区域，
// 因为它不需要收藏按钮，使用基类默认的空实现即可
}
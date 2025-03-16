// lib/widgets/components/screen/game/card/game_card.dart
import 'package:flutter/material.dart';
import '../../../../../models/game/game.dart';
import './base_game_card.dart';

/// GameCard - 基础的游戏卡片组件封装
///
/// 为了保持向后兼容性，使用BaseGameCard实现
class GameCard extends StatelessWidget {
  final Game game;

  GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return BaseGameCard(
      game: game,
      imageHeight: 160.0,
      showTags: true,
      maxTags: 2,
    );
  }
}
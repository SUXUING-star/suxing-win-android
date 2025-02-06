// lib/widgets/game/game_detail_content.dart
import 'package:flutter/material.dart';
import '../../models/game.dart';
import './game_header.dart';
import './game_description.dart';
import './game_images.dart';
import '../game/comments_section.dart';

class GameDetailContent extends StatelessWidget {
  final Game game;

  const GameDetailContent({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameHeader(game: game),
        GameDescription(game: game),
        GameImages(game: game),
        const Divider(height: 32),
        CommentsSection(gameId: game.id),
      ],
    );
  }
}
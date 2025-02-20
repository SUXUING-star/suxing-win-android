// lib/widgets/game/game_detail_content.dart
import 'package:flutter/material.dart';
import '../../models/game/game.dart';
import 'header/game_header.dart';
import 'description/game_description.dart';
import 'image/game_images.dart';
import 'comment/comments_section.dart';
import 'random/random_games_section.dart';

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
        const Divider(height: 8),
        CommentsSection(gameId: game.id),
        const Divider(height: 8),
        RandomGamesSection(currentGameId: game.id)

      ],
    );
  }
}
// lib/widgets/game/game_detail_content.dart
import 'package:flutter/material.dart';
import '../../../../models/game/game.dart';
import 'header/game_header.dart';
import 'description/game_description.dart';
import 'image/game_images.dart';
import 'comment/comments_section.dart';
import 'random/random_games_section.dart';
import 'coverImage/game_cover_image.dart';

class GameDetailContent extends StatelessWidget {
  final Game game;

  const GameDetailContent({
    Key? key,
    required this.game,
  }) : super(key: key);

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameHeader(game: game),
        GameDescription(game: game),
        GameImages(game: game),
        const Divider(height: 8),
        CommentsSection(gameId: game.id),
        const Divider(height: 8),
        RandomGamesSection(currentGameId: game.id),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column for cover image, game images and recommendations
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4/3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GameCoverImage(imageUrl: game.coverImage),
                ),
              ),
              const SizedBox(height: 24),
              GameImages(game: game),
              const SizedBox(height: 24),
              RandomGamesSection(currentGameId: game.id),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Right column for header, description and comments
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GameHeader(game: game),
              const SizedBox(height: 24),
              GameDescription(game: game),
              const SizedBox(height: 24),
              CommentsSection(gameId: game.id),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }
}
// lib/widgets/game/game_detail_content.dart
import 'package:flutter/material.dart';
import '../../../../models/game/game.dart';
import 'header/game_header.dart';
import 'description/game_description.dart';
import 'image/game_images.dart';
import 'comment/comments_section.dart';
import 'random/random_games_section.dart';
import 'coverImage/game_cover_image.dart';
import 'collection/game_collection_section.dart';
import 'collection/game_reviews_section.dart';

class GameDetailContent extends StatefulWidget {
  final Game game;

  const GameDetailContent({
    Key? key,
    required this.game,
  }) : super(key: key);

  @override
  _GameDetailContentState createState() => _GameDetailContentState();
}

class _GameDetailContentState extends State<GameDetailContent> {
  // 创建一个全局键来引用GameReviewSection
  final GlobalKey<GameReviewSectionState> _reviewSectionKey = GlobalKey<GameReviewSectionState>();

  // 当收藏状态改变时刷新评价部分
  void _refreshReviews() {
    _reviewSectionKey.currentState?.refresh();
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameHeader(game: widget.game),
        GameDescription(game: widget.game),
        GameCollectionSection(
          game: widget.game,
          onCollectionChanged: _refreshReviews, // 添加回调
        ),
        GameReviewSection(
          key: _reviewSectionKey, // 添加key
          game: widget.game,
        ),
        GameImages(game: widget.game),
        const Divider(height: 8),
        CommentsSection(gameId: widget.game.id),
        const Divider(height: 8),
        RandomGamesSection(currentGameId: widget.game.id),
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
                  child: GameCoverImage(imageUrl: widget.game.coverImage),
                ),
              ),
              const SizedBox(height: 24),
              GameImages(game: widget.game),
              const SizedBox(height: 24),
              RandomGamesSection(currentGameId: widget.game.id),
              const SizedBox(height: 24),
              GameCollectionSection(
                game: widget.game,
                onCollectionChanged: _refreshReviews, // 添加回调
              ),
              const SizedBox(height: 24),
              GameReviewSection(
                key: _reviewSectionKey, // 添加key
                game: widget.game,
              ),
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
              GameHeader(game: widget.game),
              const SizedBox(height: 24),
              GameDescription(game: widget.game),
              const SizedBox(height: 24),
              CommentsSection(gameId: widget.game.id),
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
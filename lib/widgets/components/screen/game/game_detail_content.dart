import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import '../../../../models/game/game.dart';
import 'header/game_header.dart';
import 'description/game_description.dart';
import 'image/game_images.dart';
import 'comment/comments_section.dart';
import 'random/random_games_section.dart';
import 'coverImage/game_cover_image.dart';
import 'collection/game_collection_section.dart';
import 'collection/game_reviews_section.dart';
import 'navigation/game_navigation_section.dart'; // Import the new navigation section

class GameDetailContent extends StatefulWidget {
  final Game game;
  final Function(String)? onNavigate; // 保持导航回调
  final GameCollectionItem? initialCollectionStatus;
  final Function()? onCollectionChanged;
  final Map<String, dynamic>? navigationInfo; // <--- 新增：接收导航信息

  const GameDetailContent({
    Key? key,
    required this.game,
    this.onNavigate,
    this.initialCollectionStatus,
    this.onCollectionChanged,
    this.navigationInfo, // <--- 新增构造函数参数
  }) : super(key: key);

  @override
  _GameDetailContentState createState() => _GameDetailContentState();
}

class _GameDetailContentState extends State<GameDetailContent> {
  final GlobalKey<GameReviewSectionState> _reviewSectionKey = GlobalKey<GameReviewSectionState>();

  // 内部处理收藏变化的回调 (保持不变)
  void _handleCollectionChangedInternal() {
    _reviewSectionKey.currentState?.refresh();
    widget.onCollectionChanged?.call();
  }

  // 修改：Mobile Layout, 传递 navigationInfo 给 GameNavigationSection
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameHeader(game: widget.game),
        GameDescription(game: widget.game),
        GameCollectionSection(
          game: widget.game,
          initialCollectionStatus: widget.initialCollectionStatus,
          onCollectionChanged: _handleCollectionChangedInternal,
        ),
        GameReviewSection(
          key: _reviewSectionKey,
          game: widget.game,
        ),
        GameImages(game: widget.game),
        const Divider(height: 8),
        CommentsSection(gameId: widget.game.id),
        const Divider(height: 8),
        RandomGamesSection(currentGameId: widget.game.id),
        const SizedBox(height: 24),
        const Divider(height: 8),
        const SizedBox(height: 16),
        GameNavigationSection(
          currentGameId: widget.game.id,
          navigationInfo: widget.navigationInfo, // <--- 传递导航信息
          onNavigate: widget.onNavigate,
        ),
        const SizedBox(height: 16), // 在底部增加一些空间
      ],
    );
  }

  // 修改：Desktop Layout, 传递 navigationInfo 给 GameNavigationSection
  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded( // 左侧列
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(aspectRatio: 4/3, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: GameCoverImage(imageUrl: widget.game.coverImage),),),
                  const SizedBox(height: 24),
                  GameImages(game: widget.game),
                  const SizedBox(height: 24),
                  GameCollectionSection(
                    game: widget.game,
                    initialCollectionStatus: widget.initialCollectionStatus,
                    onCollectionChanged: _handleCollectionChangedInternal,
                  ),
                  const SizedBox(height: 24),
                  GameReviewSection(key: _reviewSectionKey, game: widget.game),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded( // 右侧列
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
        ),
        const SizedBox(height: 24), const Divider(), const SizedBox(height: 16),
        RandomGamesSection(currentGameId: widget.game.id),
        const SizedBox(height: 32), const Divider(), const SizedBox(height: 16),
        GameNavigationSection(
            currentGameId: widget.game.id,
            navigationInfo: widget.navigationInfo, // <--- 传递导航信息
            onNavigate: widget.onNavigate
        ),
        const SizedBox(height: 16), // 在底部增加一些空间
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    // 使用 ValueKey 包含 gameId，确保 Game 对象变化时重建
    // 移除 SingleChildScrollView，因为 GameDetailScreen 已经处理了滚动
    return Padding(
      key: ValueKey('game_detail_content_${widget.game.id}'), // Key 依然有用
      padding: EdgeInsets.all(isDesktop ? 0 : 16.0), // 桌面布局由父级控制 Padding
      child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }
}
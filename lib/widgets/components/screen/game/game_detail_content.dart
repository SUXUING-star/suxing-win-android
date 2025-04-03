// lib/widgets/components/screen/game/game_detail_content.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/collection_change_result.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/widgets/components/screen/game/collection/game_collection_section.dart';
// 引入 GameReviewSection 本身及其 State 类（确保路径和 State 类名与你改好的版本一致）
import 'package:suxingchahui/widgets/components/screen/game/collection/game_reviews_section.dart';
import 'package:suxingchahui/widgets/components/screen/game/comment/comments_section.dart';
import 'package:suxingchahui/widgets/components/screen/game/coverImage/game_cover_image.dart'; // 确认这个是你原来的引用
import 'package:suxingchahui/widgets/components/screen/game/description/game_description.dart';
import 'package:suxingchahui/widgets/components/screen/game/header/game_header.dart';
import 'package:suxingchahui/widgets/components/screen/game/image/game_images.dart'; // 确认这个是你原来的引用
import 'package:suxingchahui/widgets/components/screen/game/navigation/game_navigation_section.dart';
import 'package:suxingchahui/widgets/components/screen/game/random/random_games_section.dart';

class GameDetailContent extends StatefulWidget {
  final Game game; // 父组件传递的游戏对象
  final Function(String)? onNavigate;
  final GameCollectionItem? initialCollectionStatus;
  final Function(CollectionChangeResult)? onCollectionChanged;
  final Map<String, dynamic>? navigationInfo;

  const GameDetailContent({
    Key? key,
    required this.game,
    this.onNavigate,
    this.initialCollectionStatus,
    this.onCollectionChanged, // *** 保持新签名 ***
    this.navigationInfo,
  }) : super(key: key);

  @override
  _GameDetailContentState createState() => _GameDetailContentState();
}

class _GameDetailContentState extends State<GameDetailContent> {
  final GlobalKey<GameReviewSectionState> _reviewSectionKey = GlobalKey<GameReviewSectionState>();

  // *** 2. 修改内部回调处理函数以接收新的结果类型，并加入 refresh() 调用 (这是必要的逻辑改动) ***
  void _handleCollectionChangedInternal(CollectionChangeResult result) { // <--- 接收结果对象
    // --- 触发 GameReviewSection 刷新 ---
    if (_reviewSectionKey.currentState != null) {
      _reviewSectionKey.currentState!.refresh(); // <--- 必要逻辑：调用 refresh 方法
    } else {
      print('GameDetailContent (${widget.game.id}): _reviewSectionKey.currentState is null. Cannot refresh reviews section.');
    }

    // --- 调用父组件 (GameDetailScreen) 的回调，传递整个结果对象 ---
    widget.onCollectionChanged?.call(result); // <--- 传递结果对象
  }

  // --- _buildMobileLayout 严格按照原始布局 ---
  Widget _buildMobileLayout() {
    // --- 保持你原来的 Column 结构和子 Widget 顺序 ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameHeader(game: widget.game), // 原来的
        GameDescription(game: widget.game), // 原来的
        // 传递更新后的回调签名给 GameCollectionSection (这是逻辑需要)
        GameCollectionSection(
          game: widget.game,
          initialCollectionStatus: widget.initialCollectionStatus,
          onCollectionChanged: _handleCollectionChangedInternal, // 传递内部处理函数
        ),
        // *** 3. 将 Key 赋给 GameReviewSection (这是必要的逻辑改动) ***
        GameReviewSection(
          key: _reviewSectionKey, // <--- 必要逻辑：设置 Key
          game: widget.game,
        ),
        GameImages(game: widget.game), // 原来的
        const Divider(height: 8), // 原来的 Divider 和 height
        CommentsSection(gameId: widget.game.id), // 原来的
        const Divider(height: 8), // 原来的 Divider 和 height
        RandomGamesSection(currentGameId: widget.game.id), // 原来的
        const SizedBox(height: 24), // 原来的 SizedBox 和 height
        const Divider(height: 8), // 原来的 Divider 和 height
        const SizedBox(height: 16), // 原来的 SizedBox 和 height
        GameNavigationSection( // 原来的
          currentGameId: widget.game.id,
          navigationInfo: widget.navigationInfo,
          onNavigate: widget.onNavigate,
        ),
        const SizedBox(height: 16), // 原来的 SizedBox 和 height
      ],
    );
  }

  // --- _buildDesktopLayout 严格按照原始布局 ---
  Widget _buildDesktopLayout() {
    // --- 保持你原来的 Column/Row 结构、Expanded flex、子 Widget 顺序、SizedBox、Divider ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row( // 原来的 Row
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧列 (原来的 Expanded 和 flex)
            Expanded(
              flex: 2, // 保持原来的 flex
              child: Column( // 原来的 Column
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 保持原来的 AspectRatio, ClipRRect, GameCoverImage
                  AspectRatio(
                    aspectRatio: 4 / 3, // 保持原来的 aspectRatio
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(12), // 保持原来的 borderRadius
                        child: GameCoverImage(imageUrl: widget.game.coverImage)
                    ),
                  ),
                  const SizedBox(height: 24), // 原来的 SizedBox
                  GameImages(game: widget.game), // 原来的
                  const SizedBox(height: 24), // 原来的 SizedBox
                  // 传递更新后的回调签名给 GameCollectionSection (逻辑需要)
                  GameCollectionSection(
                    game: widget.game,
                    initialCollectionStatus: widget.initialCollectionStatus,
                    onCollectionChanged: _handleCollectionChangedInternal,
                  ),
                  const SizedBox(height: 24), // 原来的 SizedBox
                  // *** 3. 将 Key 赋给 GameReviewSection (这是必要的逻辑改动) ***
                  GameReviewSection(
                      key: _reviewSectionKey, // <--- 必要逻辑：设置 Key
                      game: widget.game
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32), // 原来的 SizedBox
            // 右侧列 (原来的 Expanded 和 flex)
            Expanded(
              flex: 3, // 保持原来的 flex
              child: Column( // 原来的 Column
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GameHeader(game: widget.game), // 原来的
                  const SizedBox(height: 24), // 原来的 SizedBox
                  GameDescription(game: widget.game), // 原来的
                  const SizedBox(height: 24), // 原来的 SizedBox
                  CommentsSection(gameId: widget.game.id), // 原来的
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24), // 原来的 SizedBox
        const Divider(), // 原来的 Divider
        const SizedBox(height: 16), // 原来的 SizedBox
        RandomGamesSection(currentGameId: widget.game.id), // 原来的
        const SizedBox(height: 32), // 原来的 SizedBox
        const Divider(), // 原来的 Divider
        const SizedBox(height: 16), // 原来的 SizedBox
        GameNavigationSection( // 原来的
            currentGameId: widget.game.id,
            navigationInfo: widget.navigationInfo,
            onNavigate: widget.onNavigate
        ),
        const SizedBox(height: 16), // 原来的 SizedBox
      ],
    );
  }

  // --- build 方法 严格按照原始逻辑 ---
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024; // 原来的判断
    // 使用 ValueKey (你原来就有，保持)
    // Padding 的 all(16.0) 或 0 的逻辑也保持不变
    return Padding(
      key: ValueKey('game_detail_content_${widget.game.id}'), // 保持原来的 Key 逻辑
      padding: EdgeInsets.all(isDesktop ? 0 : 16.0), // 保持原来的 Padding 逻辑
      child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(), // 保持原来的选择逻辑
    );
  }
}
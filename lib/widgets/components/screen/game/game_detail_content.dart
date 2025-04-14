// lib/widgets/components/screen/game/detail/game_detail_content.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/collection_change_result.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart'; // 引入 GameCollectionStatus
import 'package:suxingchahui/widgets/components/screen/game/collection/game_collection_section.dart';
import 'package:suxingchahui/widgets/components/screen/game/collection/game_reviews_section.dart'; // 确认路径
import 'package:suxingchahui/widgets/components/screen/game/comment/comments_section.dart';
import 'package:suxingchahui/widgets/components/screen/game/coverImage/game_cover_image.dart';
import 'package:suxingchahui/widgets/components/screen/game/description/game_description.dart';
import 'package:suxingchahui/widgets/components/screen/game/header/game_header.dart';
import 'package:suxingchahui/widgets/components/screen/game/image/game_images.dart';
import 'package:suxingchahui/widgets/components/screen/game/navigation/game_navigation_section.dart';
import 'package:suxingchahui/widgets/components/screen/game/random/random_games_section.dart';

// *** 改回 StatefulWidget ***
class GameDetailContent extends StatefulWidget {
  final Game game;
  final Function(String)? onNavigate;
  final GameCollectionItem? initialCollectionStatus;
  final Function(CollectionChangeResult)? onCollectionChanged; // 保留给父级用
  final Map<String, dynamic>? navigationInfo;
  final bool isPreviewMode;

  const GameDetailContent({
    Key? key,
    required this.game,
    this.onNavigate,
    this.initialCollectionStatus,
    this.onCollectionChanged,
    this.navigationInfo,
    this.isPreviewMode = false,
  }) : super(key: key);

  @override
  // *** 创建 State ***
  _GameDetailContentState createState() => _GameDetailContentState();
}

class _GameDetailContentState extends State<GameDetailContent> {
  // *** 保留 GlobalKey ***
  final GlobalKey<GameReviewSectionState> _reviewSectionKey = GlobalKey<GameReviewSectionState>();
  // *** 记录之前的状态，用于判断是否从 Played 变过来 ***
  GameCollectionItem? _previousCollectionStatus;

  @override
  void initState() {
    super.initState();
    _previousCollectionStatus = widget.initialCollectionStatus;
  }

  @override
  void didUpdateWidget(covariant GameDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果父级传递的 initialCollectionStatus 变了，更新 previous 记录
    // 这通常发生在父级（GameDetailScreen）重新加载数据后
    if (widget.initialCollectionStatus != oldWidget.initialCollectionStatus) {
      print("GameDetailContent (${widget.game.id}): Initial status changed from parent. Updating previous status record.");
      _previousCollectionStatus = widget.initialCollectionStatus;
    }
    // 如果游戏 ID 变了，也要重置 previous 记录
    if (widget.game.id != oldWidget.game.id) {
      print("GameDetailContent (${widget.game.id}): Game ID changed. Resetting previous status record.");
      _previousCollectionStatus = widget.initialCollectionStatus; // 用新的初始状态
    }
  }

  // *** 修改内部回调处理函数 ***
  void _handleCollectionChangedInternal(CollectionChangeResult result) {
    print('GameDetailContent (${widget.game.id}): Received collection change callback. New status: ${result.newStatus?.status}');

    final newStatusString = result.newStatus?.status;
    final oldStatusString = _previousCollectionStatus?.status; // 使用 State 变量记录的旧状态

    // --- 核心逻辑：判断是否需要刷新评价区 ---
    bool shouldRefreshReviews = (newStatusString == GameCollectionStatus.played) ||
        (oldStatusString == GameCollectionStatus.played && newStatusString != GameCollectionStatus.played);

    if (shouldRefreshReviews) {
      if (!widget.isPreviewMode && _reviewSectionKey.currentState != null) {
        print('GameDetailContent (${widget.game.id}): Status changed to/from Played. Calling refresh on GameReviewSection...');
        // *** 直接用 key 调用 refresh 方法 ***
        _reviewSectionKey.currentState!.refresh();
      } else if (!widget.isPreviewMode) {
        print('GameDetailContent (${widget.game.id}): _reviewSectionKey is null or in preview mode. Cannot refresh reviews.');
      }
    } else {
      print('GameDetailContent (${widget.game.id}): Status change does not involve Played. Reviews section not refreshed.');
    }

    // *** 更新记录的 previous 状态，为下一次比较做准备 ***
    // 注意：这里不用 setState，因为这个状态只用于逻辑判断，不影响本 Widget 的 UI
    _previousCollectionStatus = result.newStatus;

    // *** 继续调用传递给父级的回调 (如果需要) ***
    // 父级（GameDetailScreen）现在只需要用这个回调来更新按钮的初始状态，不需要重新加载数据了
    widget.onCollectionChanged?.call(result);
  }

  // --- build 方法结构不变，只是确认 key 和回调传递正确 ---
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return Padding(
      key: ValueKey('game_detail_content_${widget.game.id}'),
      padding: EdgeInsets.all(isDesktop ? 0 : 16.0),
      child: isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context),
    );
  }


  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameHeader(game: widget.game),
        GameDescription(game: widget.game),
        // *** 传递 widget.game 和 内部回调 ***
        GameCollectionSection(
          game: widget.game, // 传递最新的 game 对象给它初始化
          initialCollectionStatus: widget.initialCollectionStatus,
          onCollectionChanged: _handleCollectionChangedInternal, // 传递内部回调
        ),
        // --- GameReviewSection 传递 key ---
        if (!widget.isPreviewMode)
          GameReviewSection(
            key: _reviewSectionKey, // *** 把 key 传下去 ***
            game: widget.game,
          ),
        GameImages(game: widget.game),
        if (!widget.isPreviewMode) const Divider(height: 8),
        if (!widget.isPreviewMode) CommentsSection(gameId: widget.game.id),
        const Divider(height: 8),
        RandomGamesSection(currentGameId: widget.game.id),
        const SizedBox(height: 24),
        const Divider(height: 8),
        const SizedBox(height: 16),
        GameNavigationSection(
          currentGameId: widget.game.id,
          navigationInfo: widget.navigationInfo,
          onNavigate: widget.onNavigate,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧列
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ClipRRect(borderRadius: BorderRadius.circular(12), child: GameCoverImage(imageUrl: widget.game.coverImage)),
                  ),
                  const SizedBox(height: 24),
                  GameImages(game: widget.game),
                  const SizedBox(height: 24),
                  // *** 传递 widget.game 和 内部回调 ***
                  GameCollectionSection(
                    game: widget.game, // 传递最新的 game 对象给它初始化
                    initialCollectionStatus: widget.initialCollectionStatus,
                    onCollectionChanged: _handleCollectionChangedInternal, // 传递内部回调
                  ),
                  if (!widget.isPreviewMode) const SizedBox(height: 24),
                  // --- GameReviewSection 传递 key ---
                  if (!widget.isPreviewMode)
                    GameReviewSection(
                        key: _reviewSectionKey, // *** 把 key 传下去 ***
                        game: widget.game
                    ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // 右侧列
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GameHeader(game: widget.game),
                  const SizedBox(height: 24),
                  GameDescription(game: widget.game),
                  if (!widget.isPreviewMode) const SizedBox(height: 24),
                  if (!widget.isPreviewMode) CommentsSection(gameId: widget.game.id),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        RandomGamesSection(currentGameId: widget.game.id),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        GameNavigationSection(
            currentGameId: widget.game.id,
            navigationInfo: widget.navigationInfo,
            onNavigate: widget.onNavigate
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
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
// --- 动画组件 Imports ---
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/scale_in_item.dart';


class GameDetailContent extends StatefulWidget {
  final Game game;
  final Function(String)? onNavigate;
  final GameCollectionItem? initialCollectionStatus;
  final Function(CollectionChangeResult)? onCollectionChanged;
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
  _GameDetailContentState createState() => _GameDetailContentState();
}

class _GameDetailContentState extends State<GameDetailContent> {
  final GlobalKey<GameReviewSectionState> _reviewSectionKey = GlobalKey<GameReviewSectionState>();
  GameCollectionItem? _previousCollectionStatus;

  @override
  void initState() {
    super.initState();
    _previousCollectionStatus = widget.initialCollectionStatus;
  }

  @override
  void didUpdateWidget(covariant GameDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCollectionStatus != oldWidget.initialCollectionStatus) {
      _previousCollectionStatus = widget.initialCollectionStatus;
    }
    if (widget.game.id != oldWidget.game.id) {
      _previousCollectionStatus = widget.initialCollectionStatus;
    }
  }

  void _handleCollectionChangedInternal(CollectionChangeResult result) {
    print('GameDetailContent (${widget.game.id}): Received collection change callback. New status: ${result.newStatus?.status}');
    final newStatusString = result.newStatus?.status;
    final oldStatusString = _previousCollectionStatus?.status;
    bool shouldRefreshReviews = (newStatusString == GameCollectionStatus.played) ||
        (oldStatusString == GameCollectionStatus.played && newStatusString != GameCollectionStatus.played);

    if (shouldRefreshReviews) {
      if (!widget.isPreviewMode && _reviewSectionKey.currentState != null) {
        print('GameDetailContent (${widget.game.id}): Status changed to/from Played. Calling refresh on GameReviewSection...');
        _reviewSectionKey.currentState!.refresh();
      } else if (!widget.isPreviewMode) {
        print('GameDetailContent (${widget.game.id}): _reviewSectionKey is null or in preview mode. Cannot refresh reviews.');
      }
    } else {
      print('GameDetailContent (${widget.game.id}): Status change does not involve Played. Reviews section not refreshed.');
    }
    _previousCollectionStatus = result.newStatus;
    widget.onCollectionChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    // 定义动画参数
    const Duration slideDuration = Duration(milliseconds: 400);
    const Duration fadeDuration = Duration(milliseconds: 350);
    const Duration scaleDuration = Duration(milliseconds: 450);
    const Duration baseDelay = Duration(milliseconds: 50);
    const Duration delayIncrement = Duration(milliseconds: 40);
    double slideOffset = 20.0;

    return Padding(
      // 使用 unique key 保证 Game ID 变化时重建，触发动画
      key: ValueKey('game_detail_content_${widget.game.id}'),
      padding: EdgeInsets.all(isDesktop ? 0 : 16.0),
      child: isDesktop
          ? _buildDesktopLayout(context, baseDelay, delayIncrement, slideOffset, slideDuration, fadeDuration, scaleDuration)
          : _buildMobileLayout(context, baseDelay, delayIncrement, slideOffset, slideDuration, fadeDuration, scaleDuration),
    );
  }

  // --- Mobile Layout (应用不同动画, 包含完整参数) ---
  Widget _buildMobileLayout(BuildContext context, Duration baseDelay, Duration delayIncrement, double slideOffset, Duration slideDuration, Duration fadeDuration, Duration scaleDuration) {
    int delayIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: 滑动进入
        FadeInSlideUpItem(
          key: ValueKey('header_mob_${widget.game.id}'), // 添加 Key
          duration: slideDuration,
          delay: baseDelay + (delayIncrement * delayIndex++),
          slideOffset: slideOffset,
          child: GameHeader(game: widget.game),
        ),
        // Description: 纯淡入
        FadeInItem(
          key: ValueKey('desc_mob_${widget.game.id}'), // 添加 Key
          duration: fadeDuration,
          delay: baseDelay + (delayIncrement * delayIndex++),
          child: GameDescription(game: widget.game),
        ),
        // Collection: 滑动进入 (交互区域)
        FadeInSlideUpItem(
          key: ValueKey('collection_mob_${widget.game.id}'), // 添加 Key
          duration: slideDuration,
          delay: baseDelay + (delayIncrement * delayIndex++),
          slideOffset: slideOffset,
          child: GameCollectionSection(
            game: widget.game, // 传递 game
            initialCollectionStatus: widget.initialCollectionStatus, // 传递状态
            onCollectionChanged: _handleCollectionChangedInternal, // 传递回调
          ),
        ),
        // Reviews: 滑动进入 (交互区域)
        if (!widget.isPreviewMode)
          FadeInSlideUpItem(
            key: ValueKey('reviews_mob_${widget.game.id}'), // 添加 Key
            duration: slideDuration,
            delay: baseDelay + (delayIncrement * delayIndex++),
            slideOffset: slideOffset,
            child: GameReviewSection(
              key: _reviewSectionKey, // 传递 GlobalKey
              game: widget.game, // 传递 game
            ),
          ),
        // Images: 缩放进入 (视觉元素)
        ScaleInItem(
          key: ValueKey('images_mob_${widget.game.id}'), // 添加 Key
          duration: scaleDuration,
          delay: baseDelay + (delayIncrement * delayIndex++),
          child: GameImages(game: widget.game), // 传递 game
        ),
        if (!widget.isPreviewMode) const Divider(height: 8),
        // Comments: 滑动进入 (交互区域)
        if (!widget.isPreviewMode)
          FadeInSlideUpItem(
            key: ValueKey('comments_mob_${widget.game.id}'), // 添加 Key
            duration: slideDuration,
            delay: baseDelay + (delayIncrement * delayIndex++),
            slideOffset: slideOffset,
            child: CommentsSection(gameId: widget.game.id), // 传递 gameId
          ),
        const Divider(height: 8),
        // Random Games: 淡入
        FadeInItem(
          key: ValueKey('random_mob_${widget.game.id}'), // 添加 Key
          duration: fadeDuration,
          delay: baseDelay + (delayIncrement * delayIndex++),
          child: RandomGamesSection(currentGameId: widget.game.id), // 传递 currentGameId
        ),
        const SizedBox(height: 24),
        const Divider(height: 8),
        const SizedBox(height: 16),
        // Navigation: 淡入
        FadeInItem(
          key: ValueKey('nav_mob_${widget.game.id}'), // 添加 Key
          duration: fadeDuration,
          delay: baseDelay + (delayIncrement * delayIndex++),
          child: GameNavigationSection(
            currentGameId: widget.game.id, // 传递 currentGameId
            navigationInfo: widget.navigationInfo, // 传递 navigationInfo
            onNavigate: widget.onNavigate, // 传递 onNavigate
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }


  // --- Desktop Layout (修复错误 + 应用不同动画 + 包含完整参数) ---
  Widget _buildDesktopLayout(BuildContext context, Duration baseDelay, Duration delayIncrement, double slideOffset, Duration slideDuration, Duration fadeDuration, Duration scaleDuration) {
    int leftDelayIndex = 0;
    int rightDelayIndex = 0;

    // --- 直接构建 Widget 列表，不再使用匿名函数和 expand ---
    List<Widget> children = [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Left Column ---
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover Image: 缩放进入
                ScaleInItem(
                  key: ValueKey('cover_desk_${widget.game.id}'), // 添加 Key
                  duration: scaleDuration,
                  delay: baseDelay + (delayIncrement * leftDelayIndex++),
                  child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GameCoverImage(imageUrl: widget.game.coverImage) // 传递 imageUrl
                      )
                  ),
                ),
                const SizedBox(height: 24),
                // Game Images: 缩放进入
                ScaleInItem(
                  key: ValueKey('images_desk_${widget.game.id}'), // 添加 Key
                  duration: scaleDuration,
                  delay: baseDelay + (delayIncrement * leftDelayIndex++),
                  child: GameImages(game: widget.game), // 传递 game
                ),
                const SizedBox(height: 24),
                // Collection: 滑动进入
                FadeInSlideUpItem(
                  key: ValueKey('collection_desk_${widget.game.id}'), // 添加 Key
                  duration: slideDuration,
                  delay: baseDelay + (delayIncrement * leftDelayIndex++),
                  slideOffset: slideOffset,
                  child: GameCollectionSection(
                    game: widget.game, // 传递 game
                    initialCollectionStatus: widget.initialCollectionStatus, // 传递状态
                    onCollectionChanged: _handleCollectionChangedInternal, // 传递回调
                  ),
                ),
                if (!widget.isPreviewMode) const SizedBox(height: 24),
                // Reviews: 滑动进入
                if (!widget.isPreviewMode)
                  FadeInSlideUpItem(
                      key: ValueKey('reviews_desk_${widget.game.id}'), // 添加 Key
                      duration: slideDuration,
                      delay: baseDelay + (delayIncrement * leftDelayIndex++),
                      slideOffset: slideOffset,
                      child: GameReviewSection(
                          key: _reviewSectionKey, // 传递 GlobalKey
                          game: widget.game // 传递 game
                      )
                  ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // --- Right Column ---
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: 滑动进入
                FadeInSlideUpItem(
                  key: ValueKey('header_desk_${widget.game.id}'), // 添加 Key
                  duration: slideDuration,
                  delay: baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement, // 保持稍微延迟
                  slideOffset: slideOffset,
                  child: GameHeader(game: widget.game), // 传递 game
                ),
                const SizedBox(height: 24),
                // Description: 淡入
                FadeInItem(
                  key: ValueKey('desc_desk_${widget.game.id}'), // 添加 Key
                  duration: fadeDuration,
                  delay: baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement,
                  child: GameDescription(game: widget.game), // 传递 game
                ),
                if (!widget.isPreviewMode) const SizedBox(height: 24),
                // Comments: 滑动进入
                if (!widget.isPreviewMode)
                  FadeInSlideUpItem(
                    key: ValueKey('comments_desk_${widget.game.id}'), // 添加 Key
                    duration: slideDuration,
                    delay: baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement,
                    slideOffset: slideOffset,
                    child: CommentsSection(gameId: widget.game.id), // 传递 gameId
                  ),
              ],
            ),
          ),
        ],
      ), // <-- Row 结束
    ]; // <-- children 列表初始化结束

    // --- 计算下方内容的起始索引 ---
    final bottomStartIndex = (leftDelayIndex > rightDelayIndex ? leftDelayIndex : rightDelayIndex);

    // --- 直接将下方 Widgets 添加到 children 列表中 ---
    children.addAll([
      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 16),
      // Random Games: 淡入
      FadeInItem(
        key: ValueKey('random_desk_${widget.game.id}'), // 添加 Key
        duration: fadeDuration,
        delay: baseDelay + (delayIncrement * bottomStartIndex), // 使用计算好的索引
        child: RandomGamesSection(currentGameId: widget.game.id), // 传递 currentGameId
      ),
      const SizedBox(height: 32),
      const Divider(),
      const SizedBox(height: 16),
      // Navigation: 淡入
      FadeInItem(
        key: ValueKey('nav_desk_${widget.game.id}'), // 添加 Key
        duration: fadeDuration,
        delay: baseDelay + (delayIncrement * (bottomStartIndex + 1)), // 索引 +1
        child: GameNavigationSection(
            currentGameId: widget.game.id, // 传递 currentGameId
            navigationInfo: widget.navigationInfo, // 传递 navigationInfo
            onNavigate: widget.onNavigate // 传递 onNavigate
        ),
      ),
      const SizedBox(height: 16),
    ]);

    // --- 返回包含所有 Widgets 的 Column ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children, // 直接使用构建好的 children 列表
    );
  }
}
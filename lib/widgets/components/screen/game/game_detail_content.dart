// lib/widgets/components/screen/game/detail/game_detail_content.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/collection_change_result.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart'; // 引入 GameCollectionStatus
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/widgets/components/screen/game/collection/game_collection_section.dart';
import 'package:suxingchahui/widgets/components/screen/game/collection/game_reviews_section.dart'; // 确认路径
import 'package:suxingchahui/widgets/components/screen/game/comment/game_comments_section.dart';
import 'package:suxingchahui/widgets/components/screen/game/coverImage/game_cover_image.dart';
import 'package:suxingchahui/widgets/components/screen/game/description/game_description.dart';
import 'package:suxingchahui/widgets/components/screen/game/header/game_header.dart';
import 'package:suxingchahui/widgets/components/screen/game/image/game_images.dart';
import 'package:suxingchahui/widgets/components/screen/game/music/game_music_section.dart';
import 'package:suxingchahui/widgets/components/screen/game/navigation/game_navigation_section.dart';
import 'package:suxingchahui/widgets/components/screen/game/random/random_games_section.dart';
import 'package:suxingchahui/widgets/components/screen/game/video/game_video_section.dart';
// --- 动画组件 Imports ---
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/scale_in_item.dart';

class GameDetailContent extends StatefulWidget {
  final Game game;
  final User? currentUser;
  final Function(String)? onNavigate;
  final GameCollectionItem? initialCollectionStatus;
  final Function(CollectionChangeResult)? onCollectionChanged;
  final Map<String, dynamic>? navigationInfo;
  final bool isPreviewMode;

  const GameDetailContent({
    super.key,
    required this.game,
    required this.currentUser,
    this.onNavigate,
    this.initialCollectionStatus,
    this.onCollectionChanged,
    this.navigationInfo,
    this.isPreviewMode = false,
  });

  @override
  _GameDetailContentState createState() => _GameDetailContentState();
}

class _GameDetailContentState extends State<GameDetailContent> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant GameDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _handleCollectionChangedInternal(CollectionChangeResult result) {
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
          ? _buildDesktopLayout(context, baseDelay, delayIncrement, slideOffset,
              slideDuration, fadeDuration, scaleDuration)
          : _buildMobileLayout(context, baseDelay, delayIncrement, slideOffset,
              slideDuration, fadeDuration, scaleDuration),
    );
  }

  Widget _buildHeaderSection(
      Duration duration, Duration delay, double slideOffset, Key key) {
    return FadeInSlideUpItem(
      key: key,
      duration: duration,
      delay: delay,
      slideOffset: slideOffset,
      child: GameHeader(game: widget.game, currentUser: widget.currentUser),
    );
  }

  Widget _buildDescriptionSection(Duration duration, Duration delay, Key key) {
    return FadeInItem(
      key: key,
      duration: duration,
      delay: delay,
      child: GameDescription(game: widget.game),
    );
  }

  Widget _buildCollectionStatsSection(
      Duration duration, Duration delay, double slideOffset, Key key) {
    return FadeInSlideUpItem(
      key: key,
      duration: duration,
      delay: delay,
      slideOffset: slideOffset,
      child: GameCollectionSection(
        game: widget.game,
        initialCollectionStatus: widget.initialCollectionStatus,
        onCollectionChanged: _handleCollectionChangedInternal,
        isPreviewMode: widget.isPreviewMode,
      ),
    );
  }

  Widget _buildReviewSection(bool isPreviewMode, Duration duration,
      Duration delay, double slideOffset, Key key) {
    // 注意：这里没有传递 _reviewSectionKey，因为 GameReviewSection 内部需要它
    // 如果你的 _buildReviewSection 需要接收 Key，你需要修改签名并传递它
    // 但目前看，GlobalKey 在 State 级别使用是常见的模式。
    return !isPreviewMode
        ? FadeInSlideUpItem(
            key: key, // 动画组件的 Key
            duration: duration,
            delay: delay,
            slideOffset: slideOffset,
            child: GameReviewSection(
              currentUser: widget.currentUser,
              game: widget.game,
            ),
          )
        : SizedBox.shrink();
  }

  Widget _buildImagesSection(Duration duration, Duration delay, Key key) {
    // GameImages 本身似乎不需要 ScaleInItem 的 slideOffset 参数
    return ScaleInItem(
      key: key,
      duration: duration,
      delay: delay,
      child: GameImages(game: widget.game),
    );
  }

  Widget _buildMusicSection(
      Duration duration, Duration delay, double slideOffset, Key key) {
    // 假设音乐区也用滑入效果
    return FadeInSlideUpItem(
      key: key,
      duration: duration,
      delay: delay,
      slideOffset: slideOffset,
      child: GameMusicSection(
        musicUrl: widget.game.musicUrl, // 传递 musicUrl
      ),
    );
  }

  Widget _buildVideoSection(
      Duration duration, Duration delay, double slideOffset, Key key) {
    return FadeInSlideUpItem(
      key: key,
      duration: duration,
      delay: delay,
      slideOffset: slideOffset,
      child: GameVideoSection(
        bvid: widget.game.bvid,
      ),
    );
  }

  Widget _buildCommentSection(bool isPreviewMode, Duration duration,
      Duration delay, double slideOffset, Key key) {
    return !isPreviewMode
        ? FadeInSlideUpItem(
            key: key,
            duration: duration,
            delay: delay,
            slideOffset: slideOffset,
            child: GameCommentsSection(
              gameId: widget.game.id,
              currentUser: widget.currentUser,
            ),
          )
        : SizedBox.shrink();
  }

  Widget _buildRandomSection(
      bool isPreviewMode, Duration duration, Duration delay, Key key) {
    return !isPreviewMode
        ? FadeInItem(
            key: key,
            duration: duration,
            delay: delay,
            child: RandomGamesSection(currentGameId: widget.game.id),
          )
        : SizedBox.shrink();
  }

  Widget _buildNavigationSection(
      bool isPreviewMode, Duration duration, Duration delay, Key key) {
    return !isPreviewMode
        ? FadeInItem(
            key: key,
            duration: duration,
            delay: delay,
            child: GameNavigationSection(
              currentGameId: widget.game.id,
              navigationInfo: widget.navigationInfo,
              onNavigate: widget.onNavigate,
            ),
          )
        : SizedBox.shrink();
  }

  Widget _buildMobileLayout(
      BuildContext context,
      Duration baseDelay,
      Duration delayIncrement,
      double slideOffset,
      Duration slideDuration,
      Duration fadeDuration,
      Duration scaleDuration) {
    int delayIndex = 0;
    // --- 为每个 Section 定义唯一的 Key ---
    final headerKey = ValueKey('header_mob_${widget.game.id}');
    final descriptionKey = ValueKey('desc_mob_${widget.game.id}');
    final collectionKey = ValueKey('collection_mob_${widget.game.id}');
    final reviewKey = ValueKey('reviews_mob_${widget.game.id}');
    final imageKey = ValueKey('images_mob_${widget.game.id}');
    final videoKey = ValueKey('video_section_mob_${widget.game.id}');
    final musicKey = ValueKey('music_section_mob_${widget.game.id}');
    final commentKey = ValueKey('comments_mob_${widget.game.id}');
    final randomKey = ValueKey('random_mob_${widget.game.id}');
    final navigationKey = ValueKey('nav_mob_${widget.game.id}');

    // --- 按顺序构建 Widgets ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: 滑动进入
        _buildHeaderSection(
            slideDuration,
            baseDelay + (delayIncrement * delayIndex++),
            slideOffset,
            headerKey),
        const SizedBox(height: 16), // 添加间距

        // Description: 纯淡入
        _buildDescriptionSection(fadeDuration,
            baseDelay + (delayIncrement * delayIndex++), descriptionKey),
        const SizedBox(height: 16), // 添加间距

        // Collection: 滑动进入 (交互区域)
        _buildCollectionStatsSection(
            slideDuration,
            baseDelay + (delayIncrement * delayIndex++),
            slideOffset,
            collectionKey),
        // 仅在非预览模式下显示相关内容间距
        if (!widget.isPreviewMode) const SizedBox(height: 16),

        // Reviews: 滑动进入 (交互区域)
        _buildReviewSection(
            widget.isPreviewMode,
            slideDuration,
            baseDelay + (delayIncrement * delayIndex++),
            slideOffset,
            reviewKey),
        const SizedBox(height: 16), // 添加间距

        // Images: 缩放进入 (视觉元素)
        _buildImagesSection(scaleDuration,
            baseDelay + (delayIncrement * delayIndex++), imageKey),
        const SizedBox(height: 24), // 图片后多点间距

        // Video: 滑动进入
        _buildVideoSection(slideDuration,
            baseDelay + (delayIncrement * delayIndex++), slideOffset, videoKey),
        const SizedBox(height: 16), // 添加间距

        // Music: 滑动进入
        _buildMusicSection(slideDuration,
            baseDelay + (delayIncrement * delayIndex++), slideOffset, musicKey),
        // 仅在非预览模式下显示分割线和下方内容
        if (!widget.isPreviewMode) ...[
          const SizedBox(height: 16), // 添加间距
          const Divider(height: 1), // 使用细分割线
          const SizedBox(height: 16), // 添加间距

          // Comments: 滑动进入 (交互区域)
          _buildCommentSection(
              widget.isPreviewMode,
              slideDuration,
              baseDelay + (delayIncrement * delayIndex++),
              slideOffset,
              commentKey),
          const SizedBox(height: 24), // 评论后多点间距

          // Random: 淡入
          _buildRandomSection(widget.isPreviewMode, fadeDuration,
              baseDelay + (delayIncrement * delayIndex++), randomKey),
          const SizedBox(height: 24), // 随机推荐后多点间距
          const Divider(height: 1), // 使用细分割线
          const SizedBox(height: 16), // 添加间距

          // Navigation: 淡入
          _buildNavigationSection(widget.isPreviewMode, fadeDuration,
              baseDelay + (delayIncrement * delayIndex++), navigationKey),
          const SizedBox(height: 16), // 底部留白
        ] else
          const SizedBox(height: 16), // 预览模式下底部也留点白
      ],
    );
  }

  // --- Desktop Layout (修复错误 + 应用不同动画 + 包含完整参数) ---
  Widget _buildDesktopLayout(
      BuildContext context,
      Duration baseDelay,
      Duration delayIncrement,
      double slideOffset,
      Duration slideDuration,
      Duration fadeDuration,
      Duration scaleDuration) {
    int leftDelayIndex = 0;
    int rightDelayIndex = 0;

    // --- 定义 Keys ---
    final coverKey = ValueKey('cover_desk_${widget.game.id}');
    final imagesKey = ValueKey('images_desk_${widget.game.id}');
    final collectionKey = ValueKey('collection_desk_${widget.game.id}');
    final reviewsKey = ValueKey('reviews_desk_${widget.game.id}');
    final videoKey = ValueKey('video_section_desk_${widget.game.id}');
    final musicKey = ValueKey('music_section_desk_${widget.game.id}');
    final headerKey = ValueKey('header_desk_${widget.game.id}');
    final descriptionKey = ValueKey('desc_desk_${widget.game.id}');
    final commentsKey = ValueKey('comments_desk_${widget.game.id}');
    final randomKey = ValueKey('random_desk_${widget.game.id}');
    final navigationKey = ValueKey('nav_desk_${widget.game.id}');

    // --- 构建左右列 ---
    Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cover Image: 缩放进入
        ScaleInItem(
          key: coverKey,
          duration: scaleDuration,
          delay: baseDelay + (delayIncrement * leftDelayIndex++),
          child: AspectRatio(
              aspectRatio: 16 / 9, // 桌面端封面比例可能更宽
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GameCoverImage(
                      imageUrl: widget.game.coverImage) // 传递 imageUrl
                  )),
        ),
        const SizedBox(height: 24),
        // Game Images: 缩放进入
        _buildImagesSection(scaleDuration,
            baseDelay + (delayIncrement * leftDelayIndex++), imagesKey),
        const SizedBox(height: 24),
        // Collection: 滑动进入
        _buildCollectionStatsSection(
            slideDuration,
            baseDelay + (delayIncrement * leftDelayIndex++),
            slideOffset,
            collectionKey),
        // 仅在非预览模式下显示 Review 和相关间距
        if (!widget.isPreviewMode) ...[
          const SizedBox(height: 24),
          // Reviews: 滑动进入
          _buildReviewSection(
              widget.isPreviewMode,
              slideDuration,
              baseDelay + (delayIncrement * leftDelayIndex++),
              slideOffset,
              reviewsKey),
        ],
        const SizedBox(height: 24),
        // Video: 滑动进入
        _buildVideoSection(
            slideDuration,
            baseDelay + (delayIncrement * leftDelayIndex++),
            slideOffset,
            videoKey),
        const SizedBox(height: 24),
        // Music: 滑动进入
        _buildMusicSection(
            slideDuration,
            baseDelay + (delayIncrement * leftDelayIndex++),
            slideOffset,
            musicKey),
      ],
    );

    Widget rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: 滑动进入 (比左列稍微延迟一点点，增加层次感)
        _buildHeaderSection(
            slideDuration,
            baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement,
            slideOffset,
            headerKey),
        const SizedBox(height: 24),
        // Description: 淡入
        _buildDescriptionSection(
            fadeDuration,
            baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement,
            descriptionKey),
        // 仅在非预览模式下显示评论和相关间距
        if (!widget.isPreviewMode) ...[
          const SizedBox(height: 24),
          // Comments: 滑动进入
          _buildCommentSection(
              widget.isPreviewMode,
              slideDuration,
              baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement,
              slideOffset,
              commentsKey),
        ],
      ],
    );

    // --- 计算下方内容的起始延迟索引 (取左右列中较大的那个) ---
    // 确保下方内容在两列动画基本开始后再出现
    final bottomStartIndex =
        (leftDelayIndex > rightDelayIndex ? leftDelayIndex : rightDelayIndex) +
            1; // 加1给点缓冲

    // --- 构建下方公共部分 (仅非预览模式) ---
    List<Widget> bottomSections = [];
    if (!widget.isPreviewMode) {
      bottomSections.addAll([
        const SizedBox(height: 32), // 上下分割区域
        const Divider(height: 1),
        const SizedBox(height: 24),
        // Random Games: 淡入
        _buildRandomSection(widget.isPreviewMode, fadeDuration,
            baseDelay + (delayIncrement * bottomStartIndex), randomKey),
        const SizedBox(height: 32),
        const Divider(height: 1),
        const SizedBox(height: 24),
        // Navigation: 淡入
        _buildNavigationSection(
            widget.isPreviewMode,
            fadeDuration,
            baseDelay + (delayIncrement * (bottomStartIndex + 1)),
            navigationKey), // 索引+1
        const SizedBox(height: 24), // 底部留白
      ]);
    }

    // --- 组合布局 ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: leftColumn), // 左列给稍小空间 flex 3
            const SizedBox(width: 32),
            Expanded(flex: 5, child: rightColumn), // 右列给稍大空间 flex 5
          ],
        ),
        // 将下方公共部分添加到 Column 中
        ...bottomSections,
      ],
    );
  }
}

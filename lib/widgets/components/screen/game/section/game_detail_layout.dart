// lib/widgets/components/screen/game/section/game_detail_layout.dart

/// 该文件定义了 [GameDetailLayout] 组件，一个用于展示游戏详情的布局。
/// [GameDetailLayout] 根据桌面或移动端布局，组织游戏各类信息。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/game/game/game.dart'; // 游戏模型所需
import 'package:suxingchahui/models/game/collection/collection_item.dart'; // 游戏收藏项模型所需
import 'package:suxingchahui/models/game/game/game_download_link.dart'; // 游戏下载链接模型所需
import 'package:suxingchahui/models/game/game/game_extension.dart';
import 'package:suxingchahui/models/game/game/game_navigation_info.dart'; // 游戏导航信息模型所需
import 'package:suxingchahui/models/user/user/user.dart'; // 用户模型所需
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 认证 Provider 所需
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart'; // 游戏列表筛选 Provider 所需
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 输入状态 Provider 所需
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart'; // 侧边栏 Provider 所需
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 用户信息服务所需
import 'package:suxingchahui/services/main/game/game_collection_service.dart'; // 游戏收藏服务所需
import 'package:suxingchahui/services/main/game/game_service.dart'; // 游戏服务所需
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务所需
import 'package:suxingchahui/utils/dart/func_extension.dart'; // 函数扩展方法所需
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类所需
import 'package:suxingchahui/widgets/components/screen/game/section/collection/game_collection_section.dart'; // 游戏收藏区域组件所需
import 'package:suxingchahui/widgets/components/screen/game/section/collection/game_reviews_section.dart'; // 游戏评价区域组件所需
import 'package:suxingchahui/widgets/components/screen/game/section/comment/game_comments_section.dart'; // 游戏评论区域组件所需
import 'package:suxingchahui/widgets/components/screen/game/section/coverImage/game_cover_image_section.dart'; // 游戏封面图片区域组件所需
import 'package:suxingchahui/widgets/components/screen/game/section/description/game_description_section.dart'; // 游戏描述区域组件所需
import 'package:suxingchahui/widgets/components/screen/game/section/header/game_header_section.dart'; // 游戏头部区域组件所需
import 'package:suxingchahui/widgets/components/screen/game/section/image/game_images_section.dart'; // 游戏图片区域组件所需
import 'package:suxingchahui/widgets/components/screen/game/section/music/game_music_section.dart'; // 游戏音乐区域组件所需
import 'package:suxingchahui/widgets/components/screen/game/section/navigation/game_navigation_section.dart'; // 游戏导航区域组件所需
import 'package:suxingchahui/widgets/components/screen/game/section/random/random_games_section.dart'; // 随机游戏区域组件所需
import 'package:suxingchahui/widgets/components/screen/game/section/video/game_video_section.dart'; // 游戏视频区域组件所需
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart'; // 淡入上滑动画组件所需
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 淡入动画组件所需
import 'package:suxingchahui/widgets/ui/animation/scale_in_item.dart'; // 缩放淡入动画组件所需

/// [GameDetailLayout] 类：游戏详情布局组件。
///
/// 该组件根据桌面或移动端布局，组织游戏详情页的各个部分。
class GameDetailLayout extends StatelessWidget {
  final Game game; // 游戏数据
  final bool isDesktop; // 是否为桌面布局
  final User? currentUser; // 当前用户
  final VoidCallbackString? onNavigate; // 导航回调
  final CollectionItem? collectionStatus; // 游戏收藏状态
  final GameNavigationInfo? navigationInfo; // 游戏导航信息
  final bool isPreviewMode; // 是否为预览模式
  final SidebarProvider sidebarProvider; // 侧边栏 Provider
  final UserInfoService infoService; // 用户信息服务
  final GameService gameService; // 游戏服务
  final GameCollectionService gameCollectionService; // 游戏收藏服务
  final AuthProvider authProvider; // 认证 Provider
  final UserFollowService followService; // 用户关注服务
  final InputStateService inputStateService; // 输入状态服务
  final GameListFilterProvider gameListFilterProvider; // 游戏列表筛选 Provider
  final VoidCallbackBool? onRandomSectionHover; // 随机游戏部分悬停回调
  final bool? isCollectionLoading; // 收藏操作加载状态
  final FutureVoidCallback? onCollectionButtonPressed; // 收藏按钮点击回调
  final FutureVoidCallbackObject<GameDownloadLink>?
      onAddDownloadLink; // 添加下载链接回调
  final FutureVoidCallback? onShareButtonPressed; // 分享按钮点击回调
  final bool? isLiked; // 是否已点赞
  final bool hasShared; // 是否已分享
  final bool isSharing; // 是否正在分享
  final bool isAddDownloadLink; // 是否正在添加下载链接
  final bool? isCoined; // 是否已投币
  final int coinsCount; // 投币数量
  final int likeCount; // 点赞数量
  final double rating; // 评分
  final int collectionCount; // 收藏数量
  final bool isTogglingLike; // 是否正在切换点赞状态
  final bool isTogglingCoin; // 是否正在切换投币状态
  final FutureVoidCallback? onToggleLike; // 切换点赞回调
  final FutureVoidCallback? onToggleCoin; // 切换投币回调

  final String deviceCtx; // 设备上下文标识符

  /// 构造函数。
  const GameDetailLayout({
    super.key,
    required this.gameService,
    required this.sidebarProvider,
    required this.gameCollectionService,
    required this.gameListFilterProvider,
    required this.authProvider,
    required this.infoService,
    required this.followService,
    required this.game,
    required this.isDesktop,
    required this.currentUser,
    required this.inputStateService,
    this.onNavigate,
    this.collectionStatus,
    this.navigationInfo,
    this.onRandomSectionHover,
    this.isPreviewMode = false,
    this.collectionCount = 0,
    this.rating = 0,
    this.isLiked,
    this.hasShared = false,
    this.isSharing = false,
    this.isCoined,
    this.coinsCount = 0,
    this.likeCount = 0,
    this.onToggleLike,
    this.onToggleCoin,
    this.isTogglingLike = false,
    this.isTogglingCoin = false,
    this.isAddDownloadLink = false,
    this.onAddDownloadLink,
    this.isCollectionLoading,
    this.onCollectionButtonPressed,
    this.onShareButtonPressed,
  }) : deviceCtx = isDesktop ? 'desk' : 'mob';

  /// 构建一个唯一的 [ValueKey]。
  ///
  /// [mainCtx]：主要上下文标识。
  /// 返回一个基于主要上下文、设备上下文和游戏ID的 [ValueKey]。
  ValueKey _makeValueKey(String mainCtx) =>
      ValueKey('${mainCtx}_${deviceCtx}_${game.id}');

  @override
  Widget build(BuildContext context) {
    const Duration slideDuration = Duration(milliseconds: 400); // 滑动动画时长
    const Duration fadeDuration = Duration(milliseconds: 350); // 淡入动画时长
    const Duration scaleDuration = Duration(milliseconds: 450); // 缩放动画时长
    const Duration baseDelay = Duration(milliseconds: 50); // 基础延迟
    const Duration delayIncrement = Duration(milliseconds: 40); // 延迟增量
    const double slideOffset = 20.0; // 滑动偏移量

    return Padding(
      key: ValueKey('game_detail_content_${game.id}'), // 游戏详情内容键
      padding: EdgeInsets.all(isDesktop ? 0 : 16.0), // 根据是否为桌面布局设置内边距
      child: isDesktop
          ? _buildDesktopLayout(
              // 桌面布局
              context,
              baseDelay,
              delayIncrement,
              slideOffset,
              slideDuration,
              fadeDuration,
              scaleDuration,
            )
          : _buildMobileLayout(
              // 移动布局
              context,
              baseDelay,
              delayIncrement,
              slideOffset,
              slideDuration,
              fadeDuration,
              scaleDuration,
            ),
    );
  }

  /// 构建游戏头部区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [slideOffset]：滑动偏移。
  Widget _buildHeaderSection(
      Duration duration, Duration delay, double slideOffset) {
    return FadeInSlideUpItem(
      key: _makeValueKey('header'), // 头部区域键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      slideOffset: slideOffset, // 滑动偏移
      child: GameHeaderSection(
        isDesktop: isDesktop, // 是否为桌面布局
        game: game, // 游戏数据
        currentUser: currentUser, // 当前用户
        followService: followService, // 用户关注服务
        infoService: infoService, // 用户信息服务
        onClickFilterGameTag: (context, tag) =>
            _filterTag(context, tag), // 筛选标签点击回调
        onClickFilterGameCategory: (context, category) =>
            _filterCategory(context, category), // 筛选分类点击回调
        isLiked: isLiked, // 是否已点赞
        isCoined: isCoined, // 是否已投币
        likeCount: likeCount, // 点赞数量
        coinsCount: coinsCount, // 投币数量
        isSharing: isSharing, // 是否正在分享
        hasShared: hasShared, // 是否已分享
        onShare: onShareButtonPressed, // 分享回调
        isTogglingLike: isTogglingLike, // 是否正在切换点赞状态
        isTogglingCoin: isTogglingCoin, // 是否正在切换投币状态
        onToggleLike: onToggleLike, // 切换点赞回调
        onToggleCoin: onToggleCoin, // 切换投币回调
      ),
    );
  }

  /// 根据分类筛选游戏列表并导航到主页。
  ///
  /// [context]：Build 上下文。
  /// [category]：要筛选的分类。
  void _filterCategory(BuildContext context, String category) {
    gameListFilterProvider.setCategory(category); // 设置筛选分类
    NavigationUtils.navigateToHome(sidebarProvider, context,
        tabIndex: 1); // 导航到主页
  }

  /// 根据标签筛选游戏列表并导航到主页。
  ///
  /// [context]：Build 上下文。
  /// [tag]：要筛选的标签。
  void _filterTag(BuildContext context, String tag) {
    gameListFilterProvider.setTag(tag); // 设置筛选标签
    NavigationUtils.navigateToHome(sidebarProvider, context,
        tabIndex: 1); // 导航到主页
  }

  /// 构建游戏描述区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  Widget _buildDescriptionSection(Duration duration, Duration delay) {
    return FadeInItem(
      key: _makeValueKey('description'), // 描述区域键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      child: GameDescriptionSection(
        game: game, // 游戏数据
        currentUser: currentUser, // 当前用户
        isAddDownloadLink: isAddDownloadLink, // 是否正在添加下载链接
        onAddDownloadLink: onAddDownloadLink, // 添加下载链接回调
        inputStateService: inputStateService, // 输入状态服务
        isPreview: isPreviewMode, // 是否为预览模式
      ),
    );
  }

  /// 构建游戏收藏统计区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [slideOffset]：滑动偏移。
  Widget _buildCollectionStatsSection(
      Duration duration, Duration delay, double slideOffset) {
    return FadeInSlideUpItem(
      key: _makeValueKey('collection'), // 收藏区域键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      slideOffset: slideOffset, // 滑动偏移
      child: GameCollectionSection(
        gameCollectionService: gameCollectionService, // 游戏收藏服务
        inputStateService: inputStateService, // 输入状态服务
        game: game, // 游戏数据
        currentUser: currentUser, // 当前用户
        collectionStatus: collectionStatus, // 收藏状态
        isPreviewMode: isPreviewMode, // 是否为预览模式
        isCollectionLoading: isCollectionLoading, // 收藏操作加载状态
        onCollectionButtonPressed: onCollectionButtonPressed, // 收藏按钮点击回调
      ),
    );
  }

  /// 构建游戏评价区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [slideOffset]：滑动偏移。
  Widget _buildReviewSection(
      Duration duration, Duration delay, double slideOffset) {
    return !isPreviewMode
        ? FadeInSlideUpItem(
            key: _makeValueKey('reviews'), // 评价区域键
            duration: duration, // 动画时长
            delay: delay, // 动画延迟
            slideOffset: slideOffset, // 滑动偏移
            child: GameReviewSection(
              gameCollectionService: gameCollectionService, // 游戏收藏服务
              currentUser: currentUser, // 当前用户
              game: game, // 游戏数据
              infoService: infoService, // 用户信息服务
              followService: followService, // 用户关注服务
            ),
          )
        : const SizedBox.shrink(); // 预览模式下隐藏
  }

  /// 构建游戏图片区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  Widget _buildImagesSection(Duration duration, Duration delay) {
    return ScaleInItem(
      key: _makeValueKey('images'), // 图片区域键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      child: GameImagesSection(game: game), // 游戏图片区域组件
    );
  }

  /// 构建游戏音乐区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [slideOffset]：滑动偏移。
  Widget _buildMusicSection(
      Duration duration, Duration delay, double slideOffset) {
    return FadeInSlideUpItem(
      key: _makeValueKey('music'), // 音乐区域键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      slideOffset: slideOffset, // 滑动偏移
      child: GameMusicSection(embedUrl: game.neteaseMusicEmbedUrl), // 游戏音乐区域组件
    );
  }

  /// 构建游戏视频区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [slideOffset]：滑动偏移。
  Widget _buildVideoSection(
      Duration duration, Duration delay, double slideOffset) {
    return FadeInSlideUpItem(
      key: _makeValueKey('video'), // 视频区域键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      slideOffset: slideOffset, // 滑动偏移
      child:
          GameVideoSection(bilibiliVideoUrl: game.bilibiliVideoUrl), // 游戏视频区域组件
    );
  }

  /// 构建游戏评论区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [slideOffset]：滑动偏移。
  Widget _buildCommentSection(
      Duration duration, Duration delay, double slideOffset) {
    return !isPreviewMode
        ? FadeInSlideUpItem(
            key: _makeValueKey('comments'), // 评论区域键
            duration: duration, // 动画时长
            delay: delay, // 动画延迟
            slideOffset: slideOffset, // 滑动偏移
            child: GameCommentsSection(
              authProvider: authProvider, // 认证 Provider
              inputStateService: inputStateService, // 输入状态服务
              followService: followService, // 用户关注服务
              infoService: infoService, // 用户信息服务
              gameId: game.id, // 游戏 ID
              gameService: gameService, // 游戏服务
              currentUser: currentUser, // 当前用户
            ),
          )
        : const SizedBox.shrink(); // 预览模式下隐藏
  }

  /// 构建随机游戏区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  Widget _buildRandomSection(Duration duration, Duration delay) {
    return !isPreviewMode
        ? FadeInItem(
            key: _makeValueKey('random'), // 随机游戏区域键
            duration: duration, // 动画时长
            delay: delay, // 动画延迟
            child: RandomGamesSection(
              currentGameId: game.id, // 当前游戏 ID
              gameService: gameService, // 游戏服务
              onHover: onRandomSectionHover, // 悬停回调
            ),
          )
        : const SizedBox.shrink(); // 预览模式下隐藏
  }

  /// 构建游戏导航区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  Widget _buildNavigationSection(Duration duration, Duration delay) {
    return !isPreviewMode
        ? FadeInItem(
            key: _makeValueKey('navigation'), // 导航区域键
            duration: duration, // 动画时长
            delay: delay, // 动画延迟
            child: GameNavigationSection(
              currentGameId: game.id, // 当前游戏 ID
              navigationInfo: navigationInfo, // 导航信息
              onNavigate: onNavigate, // 导航回调
            ),
          )
        : const SizedBox.shrink(); // 预览模式下隐藏
  }

  /// 构建移动端布局。
  ///
  /// [context]：Build 上下文。
  /// [baseDelay]：基础延迟。
  /// [delayIncrement]：延迟增量。
  /// [slideOffset]：滑动偏移。
  /// [slideDuration]：滑动动画时长。
  /// [fadeDuration]：淡入动画时长。
  /// [scaleDuration]：缩放动画时长。
  Widget _buildMobileLayout(
      BuildContext context,
      Duration baseDelay,
      Duration delayIncrement,
      double slideOffset,
      Duration slideDuration,
      Duration fadeDuration,
      Duration scaleDuration) {
    int delayIndex = 0; // 延迟索引
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderSection(slideDuration,
            baseDelay + (delayIncrement * delayIndex++), slideOffset), // 头部区域
        const SizedBox(height: 16), // 垂直间距
        _buildDescriptionSection(
            fadeDuration, baseDelay + (delayIncrement * delayIndex++)), // 描述区域
        const SizedBox(height: 16), // 垂直间距
        _buildCollectionStatsSection(slideDuration,
            baseDelay + (delayIncrement * delayIndex++), slideOffset), // 收藏统计区域
        if (!isPreviewMode) const SizedBox(height: 16), // 预览模式下隐藏间距
        _buildReviewSection(slideDuration,
            baseDelay + (delayIncrement * delayIndex++), slideOffset), // 评价区域
        const SizedBox(height: 16), // 垂直间距
        _buildImagesSection(
            scaleDuration, baseDelay + (delayIncrement * delayIndex++)), // 图片区域
        const SizedBox(height: 24), // 垂直间距
        _buildVideoSection(slideDuration,
            baseDelay + (delayIncrement * delayIndex++), slideOffset), // 视频区域
        const SizedBox(height: 16), // 垂直间距
        _buildMusicSection(slideDuration,
            baseDelay + (delayIncrement * delayIndex++), slideOffset), // 音乐区域
        if (!isPreviewMode) ...[
          // 预览模式下隐藏以下部分
          const SizedBox(height: 16), // 垂直间距
          const Divider(height: 1), // 分割线
          const SizedBox(height: 16), // 垂直间距
          _buildCommentSection(slideDuration,
              baseDelay + (delayIncrement * delayIndex++), slideOffset), // 评论区域
          const SizedBox(height: 24), // 垂直间距
          _buildRandomSection(fadeDuration,
              baseDelay + (delayIncrement * delayIndex++)), // 随机游戏区域
          const SizedBox(height: 24), // 垂直间距
          const Divider(height: 1), // 分割线
          const SizedBox(height: 16), // 垂直间距
          _buildNavigationSection(fadeDuration,
              baseDelay + (delayIncrement * delayIndex++)), // 导航区域
          const SizedBox(height: 16), // 垂直间距
        ] else
          const SizedBox(height: 16), // 预览模式下的垂直间距
      ],
    );
  }

  /// 构建桌面端布局。
  ///
  /// [context]：Build 上下文。
  /// [baseDelay]：基础延迟。
  /// [delayIncrement]：延迟增量。
  /// [slideOffset]：滑动偏移。
  /// [slideDuration]：滑动动画时长。
  /// [fadeDuration]：淡入动画时长。
  /// [scaleDuration]：缩放动画时长。
  Widget _buildDesktopLayout(
      BuildContext context,
      Duration baseDelay,
      Duration delayIncrement,
      double slideOffset,
      Duration slideDuration,
      Duration fadeDuration,
      Duration scaleDuration) {
    int leftDelayIndex = 0; // 左列延迟索引
    int rightDelayIndex = 0; // 右列延迟索引

    Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScaleInItem(
          key: _makeValueKey('cover'), // 封面图片键
          duration: scaleDuration, // 动画时长
          delay: baseDelay + (delayIncrement * leftDelayIndex++), // 动画延迟
          child: AspectRatio(
            aspectRatio: 16 / 9, // 宽高比
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12), // 圆角
              child:
                  GameCoverImageSection(imageUrl: game.coverImage), // 游戏封面图片区域
            ),
          ),
        ),
        const SizedBox(height: 24), // 垂直间距
        _buildImagesSection(scaleDuration,
            baseDelay + (delayIncrement * leftDelayIndex++)), // 图片区域
        const SizedBox(height: 24), // 垂直间距
        _buildCollectionStatsSection(
            slideDuration,
            baseDelay + (delayIncrement * leftDelayIndex++),
            slideOffset), // 收藏统计区域
        if (!isPreviewMode) ...[
          // 预览模式下隐藏以下部分
          const SizedBox(height: 24), // 垂直间距
          _buildReviewSection(
              slideDuration,
              baseDelay + (delayIncrement * leftDelayIndex++),
              slideOffset), // 评价区域
        ],
        const SizedBox(height: 24), // 垂直间距
        _buildVideoSection(
            slideDuration,
            baseDelay + (delayIncrement * leftDelayIndex++),
            slideOffset), // 视频区域
        const SizedBox(height: 24), // 垂直间距
        _buildMusicSection(
            slideDuration,
            baseDelay + (delayIncrement * leftDelayIndex++),
            slideOffset), // 音乐区域
      ],
    );

    Widget rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderSection(
            slideDuration,
            baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement,
            slideOffset), // 头部区域
        const SizedBox(height: 24), // 垂直间距
        _buildDescriptionSection(
            fadeDuration,
            baseDelay +
                (delayIncrement * rightDelayIndex++) +
                delayIncrement), // 描述区域
        if (!isPreviewMode) ...[
          // 预览模式下隐藏以下部分
          const SizedBox(height: 24), // 垂直间距
          _buildCommentSection(
              slideDuration,
              baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement,
              slideOffset), // 评论区域
        ],
      ],
    );

    final bottomStartIndex =
        (leftDelayIndex > rightDelayIndex ? leftDelayIndex : rightDelayIndex) +
            1; // 底部区域起始延迟索引

    List<Widget> bottomSections = []; // 底部区域列表
    if (!isPreviewMode) {
      // 预览模式下隐藏底部区域
      bottomSections.addAll([
        const SizedBox(height: 32), // 垂直间距
        const Divider(height: 1), // 分割线
        const SizedBox(height: 24), // 垂直间距
        _buildRandomSection(fadeDuration,
            baseDelay + (delayIncrement * bottomStartIndex)), // 随机游戏区域
        const SizedBox(height: 32), // 垂直间距
        const Divider(height: 1), // 分割线
        const SizedBox(height: 24), // 垂直间距
        _buildNavigationSection(fadeDuration,
            baseDelay + (delayIncrement * (bottomStartIndex + 1))), // 导航区域
        const SizedBox(height: 24), // 垂直间距
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: leftColumn), // 左列
            const SizedBox(width: 32), // 水平间距
            Expanded(flex: 5, child: rightColumn), // 右列
          ],
        ),
        ...bottomSections, // 底部区域
      ],
    );
  }
}

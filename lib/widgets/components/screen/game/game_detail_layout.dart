// lib/widgets/components/screen/game/detail/game_detail_layout.dart

/// 该文件定义了 [GameDetailLayout ]组件，一个用于展示游戏详情的布局。
/// [GameDetailLayout] 根据桌面或移动端布局，组织游戏各类信息。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/models/game/game.dart'; // 导入游戏模型
import 'package:suxingchahui/models/game/game_collection_item.dart'; // 导入游戏收藏模型
import 'package:suxingchahui/models/game/game_navigation_info.dart'; // 导入游戏导航信息模型
import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart'; // 导入游戏列表筛选 Provider
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态 Provider
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart'; // 导入侧边栏 Provider
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 导入用户信息 Provider
import 'package:suxingchahui/services/main/game/game_collection_service.dart'; // 导入游戏收藏服务
import 'package:suxingchahui/services/main/game/game_service.dart'; // 导入游戏服务
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 导入用户关注服务
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/components/screen/game/collection/game_collection_section.dart'; // 导入游戏收藏区域组件
import 'package:suxingchahui/widgets/components/screen/game/collection/game_reviews_section.dart'; // 导入游戏评论区域组件
import 'package:suxingchahui/widgets/components/screen/game/comment/game_comments_section.dart'; // 导入游戏评论组件
import 'package:suxingchahui/widgets/components/screen/game/coverImage/game_cover_image.dart'; // 导入游戏封面图片组件
import 'package:suxingchahui/widgets/components/screen/game/description/game_description.dart'; // 导入游戏描述组件
import 'package:suxingchahui/widgets/components/screen/game/header/game_header_section.dart'; // 导入游戏头部组件
import 'package:suxingchahui/widgets/components/screen/game/image/game_images_section.dart'; // 导入游戏图片组件
import 'package:suxingchahui/widgets/components/screen/game/music/game_music_section.dart'; // 导入游戏音乐组件
import 'package:suxingchahui/widgets/components/screen/game/navigation/game_navigation_section.dart'; // 导入游戏导航组件
import 'package:suxingchahui/widgets/components/screen/game/random/random_games_section.dart'; // 导入随机游戏组件
import 'package:suxingchahui/widgets/components/screen/game/video/game_video_section.dart'; // 导入游戏视频组件

import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart'; // 导入向上滑入淡入动画组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 导入淡入动画组件
import 'package:suxingchahui/widgets/ui/animation/scale_in_item.dart'; // 导入缩放淡入动画组件

/// [GameDetailLayout] 类：游戏详情布局组件。
///
/// 该组件根据桌面或移动端布局，组织游戏封面、头部、描述、收藏、评论、图片、
/// 音乐、视频、随机游戏和导航等各个区域。
class GameDetailLayout extends StatelessWidget {
  final Game game; // 游戏数据
  final bool isDesktop; // 是否为桌面布局
  final User? currentUser; // 当前登录用户
  final Function(String)? onNavigate; // 导航回调
  final GameCollectionItem? initialCollectionStatus; // 初始收藏状态
  final GameNavigationInfo? navigationInfo; // 游戏导航信息
  final bool isPreviewMode; // 是否为预览模式
  final SidebarProvider sidebarProvider; // 侧边栏 Provider
  final UserInfoService infoService; // 用户信息 Provider
  final GameService gameService; // 游戏服务
  final GameCollectionService gameCollectionService; // 游戏收藏服务
  final AuthProvider authProvider; // 认证 Provider
  final UserFollowService followService; // 用户关注服务
  final InputStateService inputStateService; // 输入状态 Provider
  final GameListFilterProvider gameListFilterProvider; // 游戏列表筛选 Provider
  final ValueChanged<bool>? onRandomSectionHover;
  final bool? isCollectionLoading;
  final VoidCallback? onCollectionButtonPressed;
  final bool? isLiked;
  final Future<void> Function(GameDownloadLink)? onAddDownloadLink;
  final bool isAddDownloadLink;
  final bool? isCoined;
  final int coinsCount;
  final int likeCount;
  final bool isTogglingLike;
  final bool isTogglingCoin;
  final VoidCallback? onToggleLike;
  final VoidCallback? onToggleCoin;

  /// 构造函数。
  ///
  /// [gameService]：游戏服务。
  /// [sidebarProvider]：侧边栏 Provider。
  /// [gameCollectionService]：游戏收藏服务。
  /// [gameListFilterProvider]：游戏列表筛选 Provider。
  /// [authProvider]：认证 Provider。
  /// [infoProvider]：用户信息 Provider。
  /// [followService]：关注服务。
  /// [game]：游戏数据。
  /// [isDesktop]：是否桌面。
  /// [currentUser]：当前用户。
  /// [inputStateService]：输入状态 Provider。
  /// [onNavigate]：导航回调。
  /// [initialCollectionStatus]：初始收藏状态。
  /// [onCollectionChanged]：收藏状态改变回调。
  /// [navigationInfo]：导航信息。
  /// [isPreviewMode]：是否预览模式。
  /// [isLiked]: 喜欢状态
  /// [isCoined]: 投币状态
  /// [onToggleLike]: 喜欢
  /// [onToggleCoin]: 投币
  /// [isTogglingLike]: 是否操作
  /// [isTogglingCoin]: 是否操作
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
    this.initialCollectionStatus,
    this.navigationInfo,
    this.onRandomSectionHover,
    this.isPreviewMode = false,
    this.isLiked,
    this.isCoined,
    this.coinsCount = 0,
    this.likeCount = 0,
    this.onToggleLike,
    this.onToggleCoin,
    this.isTogglingLike = false,
    this.isTogglingCoin = false,
    this.isAddDownloadLink = false,
    this.onAddDownloadLink,
    this.isCollectionLoading, // 可选
    this.onCollectionButtonPressed, // 可选
  });

  /// 构建游戏详情布局。
  ///
  /// 该方法根据 [isDesktop] 参数选择构建桌面或移动端布局。
  @override
  Widget build(BuildContext context) {
    const Duration slideDuration = Duration(milliseconds: 400); // 滑入动画时长
    const Duration fadeDuration = Duration(milliseconds: 350); // 淡入动画时长
    const Duration scaleDuration = Duration(milliseconds: 450); // 缩放动画时长
    const Duration baseDelay = Duration(milliseconds: 50); // 基础延迟
    const Duration delayIncrement = Duration(milliseconds: 40); // 延迟增量
    double slideOffset = 20.0; // 滑入偏移量

    return Padding(
      key: ValueKey('game_detail_content_${game.id}'), // 唯一键，用于重建触发动画
      padding: EdgeInsets.all(isDesktop ? 0 : 16.0), // 内边距
      child: isDesktop // 根据是否为桌面布局选择构建方法
          ? _buildDesktopLayout(
              context,
              baseDelay,
              delayIncrement,
              slideOffset,
              slideDuration,
              fadeDuration,
              scaleDuration,
            )
          : _buildMobileLayout(
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
  /// [slideOffset]：滑入偏移量。
  /// [key]：组件键。
  Widget _buildHeaderSection(
      Duration duration, Duration delay, double slideOffset, Key key) {
    return FadeInSlideUpItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      slideOffset: slideOffset, // 滑入偏移量
      child: GameHeader(
        isDesktop: isDesktop,
        game: game, // 游戏数据
        currentUser: currentUser, // 当前用户
        followService: followService, // 关注服务
        infoService: infoService, // 用户信息 Provider
        onClickFilterGameTag: (context, tag) => _filterTag(
          context,
          tag,
        ), // 标签点击回调
        onClickFilterGameCategory: (context, category) => _filterCategory(
          context,
          category,
        ),
        isLiked: isLiked,
        isCoined: isCoined,
        likeCount: likeCount,
        coinsCount: coinsCount,
        isTogglingLike: isTogglingLike,
        isTogglingCoin: isTogglingCoin,
        onToggleLike: onToggleLike,
        onToggleCoin: onToggleCoin, // 分类点击回调
      ),
    );
  }

  /// 筛选分类。
  ///
  /// [context]：Build 上下文。
  /// [category]：要筛选的分类。
  void _filterCategory(BuildContext context, String category) {
    gameListFilterProvider.setCategory(category); // 设置游戏列表筛选分类
    NavigationUtils.navigateToHome(
      sidebarProvider,
      context,
      tabIndex: 1,
    ); // 导航到游戏列表页
  }

  /// 筛选标签。
  ///
  /// [context]：Build 上下文。
  /// [tag]：要筛选的标签。
  void _filterTag(BuildContext context, String tag) {
    gameListFilterProvider.setTag(tag); // 设置游戏列表筛选标签
    NavigationUtils.navigateToHome(
      sidebarProvider,
      context,
      tabIndex: 1,
    ); // 导航到游戏列表页
  }

  /// 构建游戏描述区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [key]：组件键。
  Widget _buildDescriptionSection(Duration duration, Duration delay, Key key) {
    return FadeInItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      child: GameDescription(
        game: game, // 游戏数据
        currentUser: currentUser, // 当前用户
        isAddDownloadLink: isAddDownloadLink,
        onAddDownloadLink: onAddDownloadLink,
        inputStateService: inputStateService,
        isPreview: isPreviewMode,
      ),
    );
  }

  /// 构建游戏收藏统计区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [slideOffset]：滑入偏移量。
  /// [key]：组件键。
  Widget _buildCollectionStatsSection(
      Duration duration, Duration delay, double slideOffset, Key key) {
    return FadeInSlideUpItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      slideOffset: slideOffset, // 滑入偏移量
      child: GameCollectionSection(
        gameCollectionService: gameCollectionService, // 游戏收藏服务
        inputStateService: inputStateService, // 输入状态 Provider
        game: game, // 游戏数据
        currentUser: currentUser, // 当前用户
        collectionStatus: initialCollectionStatus, // 初始收藏状态
        isPreviewMode: isPreviewMode, // 是否为预览模式
        isCollectionLoading: isCollectionLoading,
        onCollectionButtonPressed: onCollectionButtonPressed,
      ),
    );
  }

  /// 构建游戏评论区域。
  ///
  /// [currentIsPreviewMode]：当前是否为预览模式。
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [slideOffset]：滑入偏移量。
  /// [key]：组件键。
  Widget _buildReviewSection(bool currentIsPreviewMode, Duration duration,
      Duration delay, double slideOffset, Key key) {
    return !currentIsPreviewMode
        ? FadeInSlideUpItem(
            key: key, // 组件键
            duration: duration, // 动画时长
            delay: delay, // 动画延迟
            slideOffset: slideOffset, // 滑入偏移量
            child: GameReviewSection(
              gameCollectionService: gameCollectionService, // 游戏收藏服务
              currentUser: currentUser, // 当前用户
              game: game, // 游戏数据
              infoService: infoService, // 用户信息 Provider
              followService: followService, // 关注服务
            ),
          )
        : const SizedBox.shrink(); // 预览模式下隐藏
  }

  /// 构建游戏图片区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [key]：组件键。
  Widget _buildImagesSection(Duration duration, Duration delay, Key key) {
    return ScaleInItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      child: GameImagesSection(game: game), // 游戏图片组件
    );
  }

  /// 构建游戏音乐区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [slideOffset]：滑入偏移量。
  /// [key]：组件键。
  Widget _buildMusicSection(
      Duration duration, Duration delay, double slideOffset, Key key) {
    return FadeInSlideUpItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      slideOffset: slideOffset, // 滑入偏移量
      child: GameMusicSection(
        musicUrl: game.musicUrl, // 音乐 URL
      ),
    );
  }

  /// 构建游戏视频区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [slideOffset]：滑入偏移量。
  /// [key]：组件键。
  Widget _buildVideoSection(
      Duration duration, Duration delay, double slideOffset, Key key) {
    return FadeInSlideUpItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      slideOffset: slideOffset, // 滑入偏移量
      child: GameVideoSection(
        bvid: game.bvid, // Bilibili 视频 ID
      ),
    );
  }

  /// 构建游戏评论区域。
  ///
  /// [currentIsPreviewMode]：当前是否为预览模式。
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [slideOffset]：滑入偏移量。
  /// [key]：组件键。
  Widget _buildCommentSection(bool currentIsPreviewMode, Duration duration,
      Duration delay, double slideOffset, Key key) {
    return !currentIsPreviewMode
        ? FadeInSlideUpItem(
            key: key, // 组件键
            duration: duration, // 动画时长
            delay: delay, // 动画延迟
            slideOffset: slideOffset, // 滑入偏移量
            child: GameCommentsSection(
              authProvider: authProvider, // 认证 Provider
              inputStateService: inputStateService, // 输入状态 Provider
              followService: followService, // 关注服务
              infoService: infoService, // 用户信息 Provider
              gameId: game.id, // 游戏 ID
              gameService: gameService, // 游戏服务
              currentUser: currentUser, // 当前用户
            ),
          )
        : const SizedBox.shrink(); // 预览模式下隐藏
  }

  /// 构建随机游戏区域。
  ///
  /// [currentIsPreviewMode]：当前是否为预览模式。
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [key]：组件键。
  Widget _buildRandomSection(
      bool currentIsPreviewMode, Duration duration, Duration delay, Key key) {
    return !currentIsPreviewMode
        ? FadeInItem(
            key: key, // 组件键
            duration: duration, // 动画时长
            delay: delay, // 动画延迟
            child: RandomGamesSection(
              currentGameId: game.id, // 当前游戏 ID
              gameService: gameService, // 游戏服务
              onHover: onRandomSectionHover,
            ),
          )
        : const SizedBox.shrink(); // 预览模式下隐藏
  }

  /// 构建游戏导航区域。
  ///
  /// [currentIsPreviewMode]：当前是否为预览模式。
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [key]：组件键。
  Widget _buildNavigationSection(
      bool currentIsPreviewMode, Duration duration, Duration delay, Key key) {
    return !currentIsPreviewMode
        ? FadeInItem(
            key: key, // 组件键
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
  /// [slideOffset]：滑入偏移量。
  /// [slideDuration]：滑入动画时长。
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
    final headerKey = ValueKey('header_mob_${game.id}'); // 头部区域键
    final descriptionKey = ValueKey('desc_mob_${game.id}'); // 描述区域键
    final collectionKey = ValueKey('collection_mob_${game.id}'); // 收藏区域键
    final reviewKey = ValueKey('reviews_mob_${game.id}'); // 评论区域键
    final imageKey = ValueKey('images_mob_${game.id}'); // 图片区域键
    final videoKey = ValueKey('video_section_mob_${game.id}'); // 视频区域键
    final musicKey = ValueKey('music_section_mob_${game.id}'); // 音乐区域键
    final commentKey = ValueKey('comments_mob_${game.id}'); // 评论区域键
    final randomKey = ValueKey('random_mob_${game.id}'); // 随机区域键
    final navigationKey = ValueKey('nav_mob_${game.id}'); // 导航区域键

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴起始对齐
      children: [
        _buildHeaderSection(
            slideDuration,
            baseDelay + (delayIncrement * delayIndex++),
            slideOffset,
            headerKey), // 头部区域
        const SizedBox(height: 16), // 间距
        _buildDescriptionSection(
            fadeDuration,
            baseDelay + (delayIncrement * delayIndex++),
            descriptionKey), // 描述区域
        const SizedBox(height: 16), // 间距
        _buildCollectionStatsSection(
            slideDuration,
            baseDelay + (delayIncrement * delayIndex++),
            slideOffset,
            collectionKey), // 收藏统计区域
        if (!isPreviewMode) const SizedBox(height: 16), // 预览模式下不显示间距
        _buildReviewSection(
            isPreviewMode,
            slideDuration,
            baseDelay + (delayIncrement * delayIndex++),
            slideOffset,
            reviewKey), // 评论区域
        const SizedBox(height: 16), // 间距
        _buildImagesSection(scaleDuration,
            baseDelay + (delayIncrement * delayIndex++), imageKey), // 图片区域
        const SizedBox(height: 24), // 间距
        _buildVideoSection(
            slideDuration,
            baseDelay + (delayIncrement * delayIndex++),
            slideOffset,
            videoKey), // 视频区域
        const SizedBox(height: 16), // 间距
        _buildMusicSection(
            slideDuration,
            baseDelay + (delayIncrement * delayIndex++),
            slideOffset,
            musicKey), // 音乐区域
        if (!isPreviewMode) ...[
          // 非预览模式下显示评论、随机和导航区域
          const SizedBox(height: 16), // 间距
          const Divider(height: 1), // 分隔线
          const SizedBox(height: 16), // 间距
          _buildCommentSection(
              isPreviewMode,
              slideDuration,
              baseDelay + (delayIncrement * delayIndex++),
              slideOffset,
              commentKey), // 评论区域
          const SizedBox(height: 24), // 间距
          _buildRandomSection(isPreviewMode, fadeDuration,
              baseDelay + (delayIncrement * delayIndex++), randomKey), // 随机游戏区域
          const SizedBox(height: 24), // 间距
          const Divider(height: 1), // 分隔线
          const SizedBox(height: 16), // 间距
          _buildNavigationSection(
              isPreviewMode,
              fadeDuration,
              baseDelay + (delayIncrement * delayIndex++),
              navigationKey), // 导航区域
          const SizedBox(height: 16), // 间距
        ] else
          const SizedBox(height: 16), // 否则显示间距
      ],
    );
  }

  /// 构建桌面端布局。
  ///
  /// [context]：Build 上下文。
  /// [baseDelay]：基础延迟。
  /// [delayIncrement]：延迟增量。
  /// [slideOffset]：滑入偏移量。
  /// [slideDuration]：滑入动画时长。
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
    int leftDelayIndex = 0; // 左侧延迟索引
    int rightDelayIndex = 0; // 右侧延迟索引

    final coverKey = ValueKey('cover_desk_${game.id}'); // 封面图片键
    final imagesKey = ValueKey('images_desk_${game.id}'); // 图片键
    final collectionKey = ValueKey('collection_desk_${game.id}'); // 收藏键
    final reviewsKey = ValueKey('reviews_desk_${game.id}'); // 评论键
    final videoKey = ValueKey('video_section_desk_${game.id}'); // 视频键
    final musicKey = ValueKey('music_section_desk_${game.id}'); // 音乐键
    final headerKey = ValueKey('header_desk_${game.id}'); // 头部键
    final descriptionKey = ValueKey('desc_desk_${game.id}'); // 描述键
    final commentsKey = ValueKey('comments_desk_${game.id}'); // 评论键
    final randomKey = ValueKey('random_desk_${game.id}'); // 随机键
    final navigationKey = ValueKey('nav_desk_${game.id}'); // 导航键

    Widget leftColumn = Column(
      // 左侧列
      crossAxisAlignment: CrossAxisAlignment.stretch, // 水平拉伸
      children: [
        ScaleInItem(
          key: coverKey, // 封面图片键
          duration: scaleDuration, // 动画时长
          delay: baseDelay + (delayIncrement * leftDelayIndex++), // 延迟
          child: AspectRatio(
            aspectRatio: 16 / 9, // 宽高比
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12), // 圆角
              child: GameCoverImage(
                imageUrl: game.coverImage, // 封面图片 URL
              ),
            ),
          ),
        ),
        const SizedBox(height: 24), // 间距
        _buildImagesSection(scaleDuration,
            baseDelay + (delayIncrement * leftDelayIndex++), imagesKey), // 图片区域
        const SizedBox(height: 24), // 间距
        _buildCollectionStatsSection(
            slideDuration,
            baseDelay + (delayIncrement * leftDelayIndex++),
            slideOffset,
            collectionKey), // 收藏统计区域
        if (!isPreviewMode) ...[
          // 非预览模式下显示评论区域
          const SizedBox(height: 24), // 间距
          _buildReviewSection(
            isPreviewMode,
            slideDuration,
            baseDelay + (delayIncrement * leftDelayIndex++),
            slideOffset,
            reviewsKey,
          ),
        ],
        const SizedBox(height: 24), // 间距
        _buildVideoSection(
            slideDuration,
            baseDelay + (delayIncrement * leftDelayIndex++),
            slideOffset,
            videoKey), // 视频区域
        const SizedBox(height: 24), // 间距
        _buildMusicSection(
            slideDuration,
            baseDelay + (delayIncrement * leftDelayIndex++),
            slideOffset,
            musicKey), // 音乐区域
      ],
    );

    Widget rightColumn = Column(
      // 右侧列
      crossAxisAlignment: CrossAxisAlignment.stretch, // 水平拉伸
      children: [
        _buildHeaderSection(
            slideDuration,
            baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement,
            slideOffset,
            headerKey), // 头部区域
        const SizedBox(height: 24), // 间距
        _buildDescriptionSection(
            fadeDuration,
            baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement,
            descriptionKey), // 描述区域
        if (!isPreviewMode) ...[
          // 非预览模式下显示评论区域
          const SizedBox(height: 24), // 间距
          _buildCommentSection(
              isPreviewMode,
              slideDuration,
              baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement,
              slideOffset,
              commentsKey),
        ],
      ],
    );

    final bottomStartIndex =
        (leftDelayIndex > rightDelayIndex ? leftDelayIndex : rightDelayIndex) +
            1; // 底部区域起始延迟索引

    List<Widget> bottomSections = []; // 底部区域列表
    if (!isPreviewMode) {
      // 非预览模式下显示随机游戏和导航区域
      bottomSections.addAll([
        const SizedBox(height: 32), // 间距
        const Divider(height: 1), // 分隔线
        const SizedBox(height: 24), // 间距
        _buildRandomSection(
            isPreviewMode,
            fadeDuration,
            baseDelay + (delayIncrement * bottomStartIndex),
            randomKey), // 随机游戏区域
        const SizedBox(height: 32), // 间距
        const Divider(height: 1), // 分隔线
        const SizedBox(height: 24), // 间距
        _buildNavigationSection(
            isPreviewMode,
            fadeDuration,
            baseDelay + (delayIncrement * (bottomStartIndex + 1)),
            navigationKey), // 导航区域
        const SizedBox(height: 24), // 间距
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴起始对齐
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴起始对齐
          children: [
            Expanded(flex: 3, child: leftColumn), // 左侧列
            const SizedBox(width: 32), // 间距
            Expanded(flex: 5, child: rightColumn), // 右侧列
          ],
        ),
        ...bottomSections, // 底部区域
      ],
    );
  }
}

// lib/widgets/components/screen/game/detail/game_detail_content.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/collection_change_result.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart'; // 引入 GameCollectionStatus
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/game/collection/game_collection_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
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

import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/scale_in_item.dart';

class GameDetailContent extends StatelessWidget {
  final Game game;
  final bool isDesktop;
  final User? currentUser;
  final Function(String)? onNavigate;
  final GameCollectionItem? initialCollectionStatus;
  final Function(CollectionChangeResult)? onCollectionChanged; // 直接是回调函数
  final Map<String, dynamic>? navigationInfo;
  final bool isPreviewMode;
  final SidebarProvider sidebarProvider;
  final UserInfoProvider infoProvider;
  final GameService gameService;
  final GameCollectionService gameCollectionService;
  final AuthProvider authProvider;
  final UserFollowService followService;
  final InputStateService inputStateService;
  final GameListFilterProvider gameListFilterProvider;

  const GameDetailContent({
    super.key, // 可以保留 super.key
    required this.gameService,
    required this.sidebarProvider,
    required this.gameCollectionService,
    required this.gameListFilterProvider,
    required this.authProvider,
    required this.infoProvider,
    required this.followService,
    required this.game,
    required this.isDesktop,
    required this.currentUser,
    required this.inputStateService,
    this.onNavigate,
    this.initialCollectionStatus,
    this.onCollectionChanged,
    this.navigationInfo,
    this.isPreviewMode = false,
  });

  @override
  Widget build(BuildContext context) {
    const Duration slideDuration = Duration(milliseconds: 400);
    const Duration fadeDuration = Duration(milliseconds: 350);
    const Duration scaleDuration = Duration(milliseconds: 450);
    const Duration baseDelay = Duration(milliseconds: 50);
    const Duration delayIncrement = Duration(milliseconds: 40);
    double slideOffset = 20.0;

    return Padding(
      // 使用 unique key 保证 Game ID 变化时重建，触发动画
      key: ValueKey('game_detail_content_${game.id}'), // 直接访问 game
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
      child: GameHeader(
        game: game,
        currentUser: currentUser,
        followService: followService,
        infoProvider: infoProvider,
        onClickFilterGameTag: (context, tag) => _filterTag(context, tag),
        onClickFilterGameCategory: (context, category) =>
            _filterCategory(context, category),
      ), //直接使用成员变量
    );
  }

  void _filterCategory(BuildContext context, String category) {
    gameListFilterProvider.setCategory(category);
    NavigationUtils.navigateToHome(sidebarProvider, context, tabIndex: 1);
  }

  void _filterTag(BuildContext context, String tag) {
    gameListFilterProvider.setTag(tag);
    NavigationUtils.navigateToHome(sidebarProvider, context, tabIndex: 1);
  }

  Widget _buildDescriptionSection(Duration duration, Duration delay, Key key) {
    return FadeInItem(
      key: key,
      duration: duration,
      delay: delay,
      child: GameDescription(
        game: game,
        currentUser: currentUser,
      ), //直接使用成员变量
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
        gameCollectionService: gameCollectionService,
        inputStateService: inputStateService,
        game: game, //直接使用成员变量
        currentUser: currentUser,
        initialCollectionStatus: initialCollectionStatus, //直接使用成员变量
        onCollectionChanged: onCollectionChanged, // 直接传递回调
        isPreviewMode: isPreviewMode, //直接使用成员变量
      ),
    );
  }

  Widget _buildReviewSection(
      bool currentIsPreviewMode,
      Duration duration, // 参数名区分
      Duration delay,
      double slideOffset,
      Key key) {
    return !currentIsPreviewMode
        ? FadeInSlideUpItem(
            key: key,
            duration: duration,
            delay: delay,
            slideOffset: slideOffset,
            child: GameReviewSection(
              gameCollectionService: gameCollectionService,
              currentUser: currentUser, //直接使用成员变量
              game: game, //直接使用成员变量
              infoProvider: infoProvider,
              followService: followService,
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildImagesSection(Duration duration, Duration delay, Key key) {
    return ScaleInItem(
      key: key,
      duration: duration,
      delay: delay,
      child: GameImages(game: game), //直接使用成员变量
    );
  }

  Widget _buildMusicSection(
      Duration duration, Duration delay, double slideOffset, Key key) {
    return FadeInSlideUpItem(
      key: key,
      duration: duration,
      delay: delay,
      slideOffset: slideOffset,
      child: GameMusicSection(
        musicUrl: game.musicUrl, //直接使用成员变量
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
        bvid: game.bvid, //直接使用成员变量
      ),
    );
  }

  Widget _buildCommentSection(
      bool currentIsPreviewMode,
      Duration duration, // 参数名区分
      Duration delay,
      double slideOffset,
      Key key) {
    return !currentIsPreviewMode
        ? FadeInSlideUpItem(
            key: key,
            duration: duration,
            delay: delay,
            slideOffset: slideOffset,
            child: GameCommentsSection(
              authProvider: authProvider,
              inputStateService: inputStateService,
              followService: followService,
              infoProvider: infoProvider,
              gameId: game.id, //直接使用成员变量
              gameService: gameService,
              currentUser: currentUser,
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildRandomSection(
      bool currentIsPreviewMode, Duration duration, Duration delay, Key key) {
    // 参数名区分
    return !currentIsPreviewMode
        ? FadeInItem(
            key: key,
            duration: duration,
            delay: delay,
            child: RandomGamesSection(
              currentGameId: game.id,
              gameService: gameService,
            ), //直接使用成员变量
          )
        : const SizedBox.shrink();
  }

  Widget _buildNavigationSection(
      bool currentIsPreviewMode, Duration duration, Duration delay, Key key) {
    // 参数名区分
    return !currentIsPreviewMode
        ? FadeInItem(
            key: key,
            duration: duration,
            delay: delay,
            child: GameNavigationSection(
              currentGameId: game.id, //直接使用成员变量
              navigationInfo: navigationInfo, //直接使用成员变量
              onNavigate: onNavigate, //直接使用成员变量
            ),
          )
        : const SizedBox.shrink();
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
    final headerKey = ValueKey('header_mob_${game.id}'); // 直接使用 game
    final descriptionKey = ValueKey('desc_mob_${game.id}');
    final collectionKey = ValueKey('collection_mob_${game.id}');
    final reviewKey = ValueKey('reviews_mob_${game.id}');
    final imageKey = ValueKey('images_mob_${game.id}');
    final videoKey = ValueKey('video_section_mob_${game.id}');
    final musicKey = ValueKey('music_section_mob_${game.id}');
    final commentKey = ValueKey('comments_mob_${game.id}');
    final randomKey = ValueKey('random_mob_${game.id}');
    final navigationKey = ValueKey('nav_mob_${game.id}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderSection(
            slideDuration,
            baseDelay + (delayIncrement * delayIndex++),
            slideOffset,
            headerKey),
        const SizedBox(height: 16),
        _buildDescriptionSection(fadeDuration,
            baseDelay + (delayIncrement * delayIndex++), descriptionKey),
        const SizedBox(height: 16),
        _buildCollectionStatsSection(
            slideDuration,
            baseDelay + (delayIncrement * delayIndex++),
            slideOffset,
            collectionKey),
        if (!isPreviewMode) const SizedBox(height: 16), // 使用 isPreviewMode
        _buildReviewSection(
            isPreviewMode, // 使用 isPreviewMode
            slideDuration,
            baseDelay + (delayIncrement * delayIndex++),
            slideOffset,
            reviewKey),
        const SizedBox(height: 16),
        _buildImagesSection(scaleDuration,
            baseDelay + (delayIncrement * delayIndex++), imageKey),
        const SizedBox(height: 24),
        _buildVideoSection(slideDuration,
            baseDelay + (delayIncrement * delayIndex++), slideOffset, videoKey),
        const SizedBox(height: 16),
        _buildMusicSection(slideDuration,
            baseDelay + (delayIncrement * delayIndex++), slideOffset, musicKey),
        if (!isPreviewMode) ...[
          // 使用 isPreviewMode
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildCommentSection(
              isPreviewMode, // 使用 isPreviewMode
              slideDuration,
              baseDelay + (delayIncrement * delayIndex++),
              slideOffset,
              commentKey),
          const SizedBox(height: 24),
          _buildRandomSection(
              isPreviewMode,
              fadeDuration, // 使用 isPreviewMode
              baseDelay + (delayIncrement * delayIndex++),
              randomKey),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildNavigationSection(
              isPreviewMode,
              fadeDuration, // 使用 isPreviewMode
              baseDelay + (delayIncrement * delayIndex++),
              navigationKey),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 16),
      ],
    );
  }

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

    final coverKey = ValueKey('cover_desk_${game.id}'); // 直接使用 game
    final imagesKey = ValueKey('images_desk_${game.id}');
    final collectionKey = ValueKey('collection_desk_${game.id}');
    final reviewsKey = ValueKey('reviews_desk_${game.id}');
    final videoKey = ValueKey('video_section_desk_${game.id}');
    final musicKey = ValueKey('music_section_desk_${game.id}');
    final headerKey = ValueKey('header_desk_${game.id}');
    final descriptionKey = ValueKey('desc_desk_${game.id}');
    final commentsKey = ValueKey('comments_desk_${game.id}');
    final randomKey = ValueKey('random_desk_${game.id}');
    final navigationKey = ValueKey('nav_desk_${game.id}');

    Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScaleInItem(
          key: coverKey,
          duration: scaleDuration,
          delay: baseDelay + (delayIncrement * leftDelayIndex++),
          child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GameCoverImage(imageUrl: game.coverImage) //直接使用成员变量
                  )),
        ),
        const SizedBox(height: 24),
        _buildImagesSection(scaleDuration,
            baseDelay + (delayIncrement * leftDelayIndex++), imagesKey),
        const SizedBox(height: 24),
        _buildCollectionStatsSection(
            slideDuration,
            baseDelay + (delayIncrement * leftDelayIndex++),
            slideOffset,
            collectionKey),
        if (!isPreviewMode) ...[
          // 使用 isPreviewMode
          const SizedBox(height: 24),
          _buildReviewSection(
              isPreviewMode, // 使用 isPreviewMode
              slideDuration,
              baseDelay + (delayIncrement * leftDelayIndex++),
              slideOffset,
              reviewsKey),
        ],
        const SizedBox(height: 24),
        _buildVideoSection(
            slideDuration,
            baseDelay + (delayIncrement * leftDelayIndex++),
            slideOffset,
            videoKey),
        const SizedBox(height: 24),
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
        _buildHeaderSection(
            slideDuration,
            baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement,
            slideOffset,
            headerKey),
        const SizedBox(height: 24),
        _buildDescriptionSection(
            fadeDuration,
            baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement,
            descriptionKey),
        if (!isPreviewMode) ...[
          // 使用 isPreviewMode
          const SizedBox(height: 24),
          _buildCommentSection(
              isPreviewMode, // 使用 isPreviewMode
              slideDuration,
              baseDelay + (delayIncrement * rightDelayIndex++) + delayIncrement,
              slideOffset,
              commentsKey),
        ],
      ],
    );

    final bottomStartIndex =
        (leftDelayIndex > rightDelayIndex ? leftDelayIndex : rightDelayIndex) +
            1;

    List<Widget> bottomSections = [];
    if (!isPreviewMode) {
      // 使用 isPreviewMode
      bottomSections.addAll([
        const SizedBox(height: 32),
        const Divider(height: 1),
        const SizedBox(height: 24),
        _buildRandomSection(
            isPreviewMode,
            fadeDuration, // 使用 isPreviewMode
            baseDelay + (delayIncrement * bottomStartIndex),
            randomKey),
        const SizedBox(height: 32),
        const Divider(height: 1),
        const SizedBox(height: 24),
        _buildNavigationSection(
            isPreviewMode, // 使用 isPreviewMode
            fadeDuration,
            baseDelay + (delayIncrement * (bottomStartIndex + 1)),
            navigationKey),
        const SizedBox(height: 24),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: leftColumn),
            const SizedBox(width: 32),
            Expanded(flex: 5, child: rightColumn),
          ],
        ),
        ...bottomSections,
      ],
    );
  }
}

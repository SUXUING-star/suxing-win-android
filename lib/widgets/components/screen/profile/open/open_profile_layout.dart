// lib/widgets/components/screen/profile/open/open_profile_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/constants/user/level_constants.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/profile/open/profile_game_card.dart';
import 'package:suxingchahui/widgets/components/screen/profile/open/profile_post_card.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/badges/safe_user_avatar.dart';
import 'package:suxingchahui/widgets/ui/badges/follow_user_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class OpenProfileLayout extends StatelessWidget {
  final User? user;
  final List<Post>? recentPosts;
  final List<Game>? publishedGames;
  final bool isCurrentUser;
  final bool isGridView;
  final TabController tabController;
  final AuthProvider authProvider; // 传递 authProvider 用于 FollowUserButton
  final UserFollowService followService; // 传递 followService
  final VoidCallback onFollowChanged; // 关注状态变化后的回调
  final String targetUserId; // 目标用户ID，给 FollowUserButton

  const OpenProfileLayout({
    super.key,
    required this.user,
    required this.recentPosts,
    required this.publishedGames,
    required this.isCurrentUser,
    required this.isGridView,
    required this.tabController,
    required this.authProvider,
    required this.followService,
    required this.onFollowChanged,
    required this.targetUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = DeviceUtils.isDesktopScreen(context);
    // 使用传入的 user?.id 或 targetUserId 作为 ValueKey 的一部分，确保用户切换时动画能正确执行
    final contentKey =
        ValueKey<String>('profile_layout_${user?.id ?? targetUserId}');

    if (isDesktop) {
      return _buildDesktopLayout(context, contentKey, isDesktop: isDesktop);
    } else {
      return _buildMobileLayout(context, contentKey, isDesktop: isDesktop);
    }
  }

  Widget _buildDesktopLayout(BuildContext context, Key animationKey,
      {required bool isDesktop}) {
    const Duration initialDelay = Duration(milliseconds: 100);
    const Duration stagger = Duration(milliseconds: 150);

    return Row(
      key: animationKey,
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeInSlideUpItem(
                    delay: initialDelay,
                    child: _buildUserHeader(context, isDesktop: isDesktop),
                  ),
                  const SizedBox(height: 16),
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger,
                    child: _buildUserStatistics(context),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: FadeInSlideUpItem(
            delay: initialDelay + stagger * 2,
            child: _buildContentSection(context, isDesktop: isDesktop),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, Key animationKey,
      {required bool isDesktop}) {
    const Duration initialDelay = Duration(milliseconds: 100);
    const Duration stagger = Duration(milliseconds: 150);

    return Column(
      key: animationKey,
      children: [
        FadeInSlideUpItem(
          delay: initialDelay,
          child: _buildUserHeader(context, isDesktop: isDesktop),
        ),
        Expanded(
          child: FadeInSlideUpItem(
            delay: initialDelay + stagger,
            child: _buildContentSection(context, isDesktop: isDesktop),
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeader(BuildContext context, {required bool isDesktop}) {
    if (user == null) return const SizedBox.shrink();

    final double avatarRadius = isDesktop ? 50.0 : 38.0;
    final EdgeInsets cardMargin = isDesktop
        ? const EdgeInsets.all(12)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 8);
    final EdgeInsets cardPadding =
        isDesktop ? const EdgeInsets.all(16) : const EdgeInsets.all(12);
    final double verticalSpacingSmall = isDesktop ? 8.0 : 4.0;
    final double verticalSpacingMedium = isDesktop ? 12.0 : 8.0;
    final TextStyle? usernameStyle = isDesktop
        ? Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18);
    final TextStyle xpStyle = isDesktop
        ? TextStyle(fontSize: 14, color: Colors.grey[600])
        : TextStyle(fontSize: 12, color: Colors.grey[600]);
    final TextStyle signatureStyle = isDesktop
        ? TextStyle(
            fontSize: 12,
            color: Colors.black.withSafeOpacity(0.75),
            height: 1.35)
        : TextStyle(
            fontSize: 11,
            color: Colors.black.withSafeOpacity(0.70),
            height: 1.3);
    final int signatureMaxLines = isDesktop ? 3 : 2;
    final double levelFontSize = isDesktop ? 12 : 10;
    final double createTimeFontSize = isDesktop ? 12 : 10;

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int calculatedMemCacheSize =
        (avatarRadius * 2 * devicePixelRatio).round();

    final String signatureText = user?.signature?.trim() ?? '';
    final bool hasSignature = signatureText.isNotEmpty;

    final User? currentUser = authProvider.currentUser;
    bool iFollowTarget = false;
    String? currentUserId = currentUser?.id;
    if (currentUserId != null && currentUser != null) {
      iFollowTarget = currentUser.following.contains(user?.id);
    }

    return Card(
      margin: cardMargin,
      elevation: isDesktop ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
      ),
      child: Padding(
        padding: cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SafeUserAvatar(
              isAdmin: user?.isAdmin ?? false,
              isSuperAdmin: user?.isSuperAdmin ?? false,
              userId: user?.id,
              avatarUrl: user?.avatar,
              username: user?.username ?? '',
              radius: avatarRadius,
              enableNavigation: false,
              memCacheWidth: calculatedMemCacheSize,
              memCacheHeight: calculatedMemCacheSize,
            ),
            SizedBox(height: verticalSpacingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    user?.username ?? '',
                    style: usernameStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: isDesktop ? 8 : 6),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 8 : 6,
                      vertical: isDesktop ? 2 : 1.5),
                  decoration: BoxDecoration(
                    color: _getLevelColor(user?.level ?? 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv.${user?.level ?? 1}',
                    style: TextStyle(
                      fontSize: levelFontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: verticalSpacingSmall),
            Text(
              '${user?.experience ?? 0} XP',
              style: xpStyle,
            ),
            SizedBox(height: verticalSpacingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFollowInfo(context, '关注', user?.following.length ?? 0,
                    isDesktop: isDesktop),
                SizedBox(width: isDesktop ? 20 : 16),
                _buildFollowInfo(context, '粉丝', user?.followers.length ?? 0,
                    isDesktop: isDesktop),
              ],
            ),
            if (hasSignature) ...[
              SizedBox(height: verticalSpacingMedium),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: isDesktop ? 24.0 : 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: isDesktop ? 18 : 14,
                      color: Colors.grey.shade500,
                    ),
                    SizedBox(width: isDesktop ? 6 : 4),
                    Flexible(
                      child: AppText(
                        signatureText,
                        textAlign: TextAlign.center,
                        style: signatureStyle,
                        maxLines: signatureMaxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: verticalSpacingMedium),
            Text(
              '创建于 ${_formatDate(user?.createTime)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: createTimeFontSize,
                  ),
            ),
            SizedBox(height: verticalSpacingMedium),
            if (!isCurrentUser)
              Transform.scale(
                scale: isDesktop ? 1.0 : 0.95,
                child: FollowUserButton(
                  currentUser: authProvider.currentUser, // 使用传入的 authProvider
                  followService: followService, // 使用传入的 followService
                  targetUserId: targetUserId, // 使用传入的 targetUserId
                  showIcon: true,
                  initialIsFollowing: iFollowTarget,
                  onFollowChanged: onFollowChanged, // 使用传入的回调
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildFollowInfo(BuildContext context, String label, int count,
      {required bool isDesktop}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isDesktop ? 16 : 14,
          ),
        ),
        SizedBox(height: isDesktop ? 2 : 1),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isDesktop ? 14 : 12,
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(BuildContext context, {required bool isDesktop}) {
    final tabTextStyle = TextStyle(fontSize: isDesktop ? null : 12.5);
    final iconSize = isDesktop ? null : 20.0;

    return Column(
      children: [
        TabBar(
          controller: tabController, // 使用传入的 tabController
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
          labelPadding:
              isDesktop ? null : const EdgeInsets.symmetric(horizontal: 8.0),
          labelStyle: isDesktop
              ? null
              : tabTextStyle.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: isDesktop ? null : tabTextStyle,
          tabs: [
            Tab(
              icon: Icon(Icons.videogame_asset, size: iconSize),
              child: Text(
                '游戏 ${publishedGames?.length ?? 0}',
                style: tabTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Tab(
              icon: Icon(Icons.forum, size: iconSize),
              child: Text(
                '帖子 ${recentPosts?.length ?? 0}',
                style: tabTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabController, // 使用传入的 tabController
            children: [
              _buildGamesContent(context, isDesktop: isDesktop),
              _buildPostsContent(context, isDesktop: isDesktop),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGamesContent(BuildContext context, {required bool isDesktop}) {
    if (publishedGames == null || publishedGames!.isEmpty) {
      return const EmptyStateWidget(
          message: '暂无发布的游戏', iconData: Icons.videogame_asset);
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      child: isGridView ? _buildGamesGrid(context) : _buildGamesList(context),
    );
  }

  Widget _buildPostsContent(BuildContext context, {required bool isDesktop}) {
    if (recentPosts == null || recentPosts!.isEmpty) {
      return const EmptyStateWidget(message: '暂无发布的帖子', iconData: Icons.forum);
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      child: _buildPostsList(context),
    );
  }

  Widget _buildGamesList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: publishedGames!.length,
      itemBuilder: (context, index) {
        return FadeInSlideUpItem(
          delay: Duration(milliseconds: 50 * index),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: ProfileGameCard(
              game: publishedGames![index],
              isGridItem: false,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGamesGrid(BuildContext context) {
    final crossAxisCount = DeviceUtils.calculateGameCardsInGameListPerRow(context);
    final cardRatio = DeviceUtils.calculateSimpleGameCardRatio(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: cardRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: publishedGames!.length,
      itemBuilder: (context, index) {
        return FadeInSlideUpItem(
          delay: Duration(milliseconds: 50 * index),
          child: ProfileGameCard(
            game: publishedGames![index],
            isGridItem: true,
          ),
        );
      },
    );
  }

  Widget _buildPostsList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentPosts!.length,
      itemBuilder: (context, index) {
        return FadeInSlideUpItem(
          delay: Duration(milliseconds: 50 * index),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ProfilePostCard(post: recentPosts![index]),
          ),
        );
      },
    );
  }

  Widget _buildUserStatistics(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '用户统计',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              icon: Icons.videogame_asset,
              title: '发布游戏',
              value: publishedGames?.length.toString() ?? '0',
              color: Colors.blue,
            ),
            const Divider(height: 24),
            _buildStatRow(
              context,
              icon: Icons.forum,
              title: '发布帖子',
              value: recentPosts?.length.toString() ?? '0',
              color: Colors.green,
            ),
            const Divider(height: 24),
            _buildStatRow(
              context,
              icon: Icons.calendar_today,
              title: '连续签到',
              value: '${user?.consecutiveCheckIn ?? 0} 天',
              color: Colors.orange,
            ),
            const Divider(height: 24),
            _buildStatRow(
              context,
              icon: Icons.check_circle_outline,
              title: '累计签到',
              value: '${user?.totalCheckIn ?? 0} 天',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withSafeOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateTimeFormatter.formatStandard(date);
  }

  Color _getLevelColor(int level) {
    return LevelUtils.getLevelColor(level);
  }
}

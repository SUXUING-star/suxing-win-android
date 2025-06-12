// lib/widgets/components/screen/profile/open/open_profile_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/constants/user/level_constants.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/forum/card/base_post_card.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_content_grid.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_list_view.dart';
import 'package:suxingchahui/widgets/ui/badges/safe_user_avatar.dart';
import 'package:suxingchahui/widgets/ui/badges/follow_user_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/components/game/common_game_card.dart';
import 'package:suxingchahui/widgets/ui/components/user/user_signature.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class OpenProfileLayout extends StatelessWidget {
  final User targetUser;
  final List<Post>? recentPosts;
  final List<Game>? publishedGames;
  final bool isGridView;
  final TabController tabController;
  final AuthProvider authProvider; // 传递 authProvider 用于 FollowUserButton
  final double screenWidth;
  final UserFollowService followService; // 传递 followService
  final UserInfoProvider infoProvider;
  final VoidCallback onFollowChanged; // 关注状态变化后的回调
  final bool isDesktop;

  static const desktopLeftFlex = 1;
  static const desktopRightFlex = 2;

  const OpenProfileLayout({
    super.key,
    required this.targetUser,
    required this.recentPosts,
    required this.publishedGames,
    required this.isGridView,
    required this.tabController,
    required this.authProvider,
    required this.followService,
    required this.infoProvider,
    required this.onFollowChanged,
    required this.screenWidth,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    // 使用传入的 user?.id 或 targetUserId 作为 ValueKey 的一部分，确保用户切换时动画能正确执行
    final contentKey = ValueKey<String>('profile_layout_${targetUser.id}');

    return isDesktop
        ? _buildDesktopLayout(context, contentKey)
        : _buildMobileLayout(context, contentKey);
  }

  Widget _buildDesktopLayout(BuildContext context, Key animationKey) {
    return Row(
      key: animationKey,
      children: [
        Expanded(
          flex: desktopLeftFlex,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildUserHeader(context),
                  const SizedBox(height: 16),
                  _buildUserStatistics(context),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: desktopRightFlex,
          child: _buildContentSection(
            context,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    Key animationKey,
  ) {
    return Column(
      key: animationKey,
      children: [
        _buildUserHeader(context),
        Expanded(
          child: _buildContentSection(
            context,
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    final double avatarRadius = isDesktop ? 36.0 : 24.0;
    final EdgeInsets cardMargin = isDesktop
        ? const EdgeInsets.all(12)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 8);
    final EdgeInsets cardPadding =
        isDesktop ? const EdgeInsets.all(8) : const EdgeInsets.all(6);
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
            ?.copyWith(fontWeight: FontWeight.bold, fontSize: 14);
    final TextStyle xpStyle = isDesktop
        ? TextStyle(fontSize: 14, color: Colors.grey[600])
        : TextStyle(fontSize: 12, color: Colors.grey[600]);

    final double levelFontSize = isDesktop ? 12 : 10;
    final double createTimeFontSize = isDesktop ? 12 : 10;

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int calculatedMemCacheSize =
        (avatarRadius * 2 * devicePixelRatio).round();

    final String signatureText = targetUser.signature?.trim() ?? '';
    final bool hasSignature = signatureText.isNotEmpty;

    final User? currentUser = authProvider.currentUser;
    bool iFollowTarget = false;
    String? currentUserId = currentUser?.id;
    if (currentUserId != null && currentUser != null) {
      iFollowTarget = currentUser.following.contains(targetUser.id);
    }

    final String targetUserId = targetUser.id;

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
              isAdmin: targetUser.isAdmin,
              isSuperAdmin: targetUser.isSuperAdmin,
              userId: targetUser.id,
              avatarUrl: targetUser.avatar,
              username: targetUser.username,
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
                    targetUser.username,
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
                    color: _getLevelColor(targetUser.level),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv.${targetUser.level}',
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
              '${targetUser.experience} XP',
              style: xpStyle,
            ),
            SizedBox(height: verticalSpacingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFollowInfo(context, '关注', targetUser.following.length,
                    isDesktop: isDesktop),
                SizedBox(width: isDesktop ? 20 : 16),
                _buildFollowInfo(context, '粉丝', targetUser.followers.length,
                    isDesktop: isDesktop),
              ],
            ),
            if (hasSignature) ...[
              SizedBox(height: verticalSpacingMedium),
              UserSignature(
                isDesktop: isDesktop,
                signature: signatureText,
              )
            ],
            SizedBox(height: verticalSpacingMedium),
            Text(
              '创建于 ${_formatDate(targetUser.createTime)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: createTimeFontSize,
                  ),
            ),
            SizedBox(height: verticalSpacingMedium),
            if (currentUserId != targetUserId)
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

  Widget _buildContentSection(BuildContext context) {
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
      child: _buildPostsGridOrList(context),
    );
  }

  Widget _buildGamesList(BuildContext context) {
    return AnimatedListView<Game>(
      items: publishedGames!,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemBuilder: (context, index, game) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: CommonGameCard(
            game: game,
            isGridItem: false,
          ),
        );
      },
    );
  }

  Widget _buildGamesGrid(BuildContext context) {
    double availableWidth;
    if (isDesktop) {
      availableWidth =
          screenWidth * desktopRightFlex / (desktopRightFlex + desktopLeftFlex);
    } else {
      availableWidth = screenWidth;
    }

    final crossAxisCount = DeviceUtils.calculateGameCardsInGameListPerRow(
      context,
      directAvailableWidth: availableWidth,
      isCompact: true,
    );
    final cardRatio = DeviceUtils.calculateGameCardRatio(
      context,
      directAvailableWidth: availableWidth,
    );

    if (publishedGames == null || publishedGames!.isEmpty) {
      return const EmptyStateWidget(message: "没有任何发表");
    }

    return AnimatedContentGrid<Game>(
      items: publishedGames!,
      crossAxisCount: crossAxisCount,
      childAspectRatio: cardRatio,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemBuilder: (context, index, game) {
        return CommonGameCard(
          game: game,
          isGridItem: true,
        );
      },
    );
  }

  Widget _buildPostsGridOrList(BuildContext context) {
    double availableWidth;
    if (isDesktop) {
      availableWidth =
          screenWidth * desktopRightFlex / (desktopRightFlex + desktopLeftFlex);
    } else {
      availableWidth = screenWidth;
    }

    final crossAxisCount = DeviceUtils.calculatePostCardsPerRow(
      context,
      directAvailableWidth: availableWidth,
    );
    final cardRatio = DeviceUtils.calculatePostCardRatio(
      context,
      directAvailableWidth: availableWidth,
    );
    if (recentPosts == null || recentPosts!.isEmpty) {
      return const EmptyStateWidget(message: "没有任何发表");
    }
    return AnimatedContentGrid<Post>(
      items: recentPosts!,
      shrinkWrap: true,
      crossAxisCount: crossAxisCount,
      childAspectRatio: cardRatio,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemBuilder: (context, index, post) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: BasePostCard(
            post: post,
            followService: followService,
            availableWidth: screenWidth,
            currentUser: authProvider.currentUser,
            infoProvider: infoProvider,
          ),
        );
      },
    );
  }

  Widget _buildUserStatistics(BuildContext context) {
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
              value: '${targetUser.consecutiveCheckIn ?? 0} 天',
              color: Colors.orange,
            ),
            const Divider(height: 24),
            _buildStatRow(
              context,
              icon: Icons.check_circle_outline,
              title: '累计签到',
              value: '${targetUser.totalCheckIn ?? 0} 天',
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

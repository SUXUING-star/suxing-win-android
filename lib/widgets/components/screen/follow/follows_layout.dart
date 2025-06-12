// lib/widgets/components/screen/follow/follows_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_content_grid.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

/// `FollowsLayout` 是一个纯UI组件，负责展示关注/粉丝页面的布局。
///
/// 它接收所有需要的数据和状态，并根据 `isDesktopLayout` 和 `screenWidth`
/// 来决定渲染桌面还是移动端布局。所有业务逻辑和状态管理都在其父组件中处理。
class FollowsLayout extends StatelessWidget {
  /// 当前登录用户。
  final User? currentUser;

  /// 用户信息提供者。
  final UserInfoProvider infoProvider;

  /// 用户关注服务。
  final UserFollowService followService;

  /// 用于切换“关注”和“粉丝”列表的 Tab 控制器。
  final TabController tabController;

  /// 关注列表的用户ID。
  final List<String>? followingsIDs;

  /// 粉丝列表的用户ID。
  final List<String>? followersIDs;

  /// 指示是否正在加载目标用户数据的标志。
  final bool isLoadingTargetUser;

  /// 正在查看的用户的ID。
  final String viewingUserId;

  /// 用于下拉刷新的回调函数。
  final Future<void> Function() onRefreshTargetUser;

  /// 是否为桌面布局。
  final bool isDesktopLayout;

  /// 屏幕宽度，由上层组件传入。
  final double screenWidth;

  /// 桌面布局下，左侧统计面板的 flex 比例。
  static const int desktopStatsFlex = 1;

  /// 桌面布局下，右侧内容区域的 flex 比例。
  static const int desktopContentFlex = 3;

  const FollowsLayout({
    super.key,
    required this.infoProvider,
    required this.followService,
    required this.currentUser,
    required this.tabController,
    required this.followingsIDs,
    required this.followersIDs,
    required this.isLoadingTargetUser,
    required this.viewingUserId,
    required this.onRefreshTargetUser,
    required this.isDesktopLayout,
    required this.screenWidth,
  });

  /// 计算互相关注的用户数量。
  int get _mutualFollowsCount {
    if (followingsIDs == null || followersIDs == null) {
      return 0;
    }
    final followingSet = followingsIDs!.toSet();
    final followerSet = followersIDs!.toSet();
    return followingSet.intersection(followerSet).length;
  }

  @override
  Widget build(BuildContext context) {
    return isDesktopLayout
        ? _buildDesktopLayout(context)
        : _buildMobileLayout(context);
  }

  /// 构建桌面端布局。
  ///
  /// 左侧为统计面板，右侧为带Tab的内容区。
  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: desktopStatsFlex,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFollowStatistics(context, isDesktop: true),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 0.5),
          Expanded(
            flex: desktopContentFlex,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _buildFollowsContent(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建移动端布局。
  ///
  /// 顶部为统计面板，下方为带Tab的内容区。
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _buildFollowStatistics(context, isDesktop: false),
        ),
        Expanded(
          child: _buildFollowsContent(context),
        ),
      ],
    );
  }

  /// 构建统计信息面板。
  Widget _buildFollowStatistics(BuildContext context,
      {required bool isDesktop}) {
    final cardPadding =
        isDesktop ? const EdgeInsets.all(16) : const EdgeInsets.all(12);
    final titleStyle = TextStyle(
        fontSize: isDesktop ? 18 : 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color);
    return Card(
      elevation: isDesktop ? 2 : 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDesktop ? 12 : 10)),
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('社交统计', style: titleStyle),
            const SizedBox(height: 16),
            _buildStatRow(context,
                isDesktop: isDesktop,
                icon: Icons.people_outline,
                title: '正在关注',
                value: followingsIDs?.length.toString() ?? '0',
                color: Colors.blueAccent),
            const SizedBox(height: 8),
            _buildStatRow(context,
                isDesktop: isDesktop,
                icon: Icons.star_outline,
                title: '粉丝',
                value: followersIDs?.length.toString() ?? '0',
                color: Colors.pinkAccent),
            const SizedBox(height: 8),
            _buildStatRow(context,
                isDesktop: isDesktop,
                icon: Icons.swap_horiz,
                title: '互相关注',
                value: _mutualFollowsCount.toString(),
                color: Colors.green),
          ],
        ),
      ),
    );
  }

  /// 构建单行统计信息。
  Widget _buildStatRow(BuildContext context,
      {required bool isDesktop,
      required IconData icon,
      required String title,
      required String value,
      required Color color}) {
    final titleTextStyle = TextStyle(
        color:
            Theme.of(context).textTheme.bodyMedium?.color?.withSafeOpacity(0.7),
        fontSize: isDesktop ? 14 : 13);
    final valueTextStyle = TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: isDesktop ? 16 : 15,
        color: Theme.of(context).textTheme.bodyLarge?.color);
    final iconSize = isDesktop ? 22.0 : 20.0;
    return Row(children: [
      Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withSafeOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: iconSize)),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: titleTextStyle),
        const SizedBox(height: 2),
        Text(value, style: valueTextStyle)
      ])
    ]);
  }

  /// 构建关注/粉丝列表的内容区域，包含 TabBar 和 TabBarView。
  Widget _buildFollowsContent(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: tabController,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: [
            Tab(text: '关注 (${followingsIDs?.length ?? 0})'),
            Tab(text: '粉丝 (${followersIDs?.length ?? 0})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              _buildUserGrid(context,
                  userIds: followingsIDs, isFollowingList: true),
              _buildUserGrid(context,
                  userIds: followersIDs, isFollowingList: false),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建用户网格列表。
  Widget _buildUserGrid(BuildContext context,
      {List<String>? userIds, required bool isFollowingList}) {
    if (isLoadingTargetUser && (userIds == null || userIds.isEmpty)) {
      return LoadingWidget(
          message: isFollowingList ? "加载关注列表..." : "加载粉丝列表...");
    }
    if (userIds?.isEmpty ?? true) {
      return EmptyStateWidget(
        iconData: isFollowingList
            ? Icons.person_search_outlined
            : Icons.no_accounts_outlined,
        message: isFollowingList ? '还没有关注任何人' : '还没有粉丝',
        action:
            FunctionalTextButton(onPressed: onRefreshTargetUser, label: '刷新看看'),
      );
    }

    // 根据从顶层传来的 screenWidth 和 isDesktopLayout 手动计算可用宽度
    double availableWidth;
    if (isDesktopLayout) {
      const double horizontalPadding =
          16 + 8; // Row的padding(16) + Expanded的padding(8)
      const double dividerWidth = 1.0;
      availableWidth = (screenWidth - horizontalPadding * 2 - dividerWidth) *
          desktopContentFlex /
          (desktopStatsFlex + desktopContentFlex);
    } else {
      availableWidth = screenWidth;
    }

    const double targetCardWidth = 220.0;
    const double gridPadding = 12.0 * 2;
    const double crossAxisSpacing = 12.0;
    final effectiveWidth = availableWidth - gridPadding;
    final crossAxisCount = ((effectiveWidth + crossAxisSpacing) /
            (targetCardWidth + crossAxisSpacing))
        .floor()
        .clamp(1, 4);

    return RefreshIndicator(
      onRefresh: onRefreshTargetUser,
      child: AnimatedContentGrid<String>(
        items: userIds!,
        padding: const EdgeInsets.all(12),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isDesktopLayout ? 3.0 : 2.6,
        itemBuilder: (context, index, targetUserId) =>
            _buildUserCard(context, targetUserId),
      ),
    );
  }

  /// 构建单个用户卡片。
  Widget _buildUserCard(BuildContext context, String targetUserId) {
    return Card(
      key: ValueKey(targetUserId),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserInfoBadge(
                infoProvider: infoProvider,
                followService: followService,
                targetUserId: targetUserId,
                currentUser: currentUser,
                showFollowButton: true,
                mini: true),
          ],
        ),
      ),
    );
  }
}

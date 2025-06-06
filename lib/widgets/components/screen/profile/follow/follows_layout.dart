import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';

class FollowsLayout extends StatelessWidget {
  final User? currentUser;
  final UserInfoProvider infoProvider;
  final UserFollowService followService;
  final TabController tabController;
  final List<String>? followingsIDs;
  final List<String>? followersIDs;
  final bool isLoadingTargetUser;
  final String viewingUserId;
  final Future<void> Function() onRefreshTargetUser;

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
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = DeviceUtils.isDesktop;
    final isTablet = DeviceUtils.isTablet(context);
    final isLandscape = DeviceUtils.isLandscape(context);

    if (isDesktop || (isTablet && isLandscape)) {
      return _buildDesktopLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  Widget _buildDesktopLayout(BuildContext context) {
    const Duration initialDelay = Duration(milliseconds: 100);
    const Duration stagger = Duration(milliseconds: 150);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FadeInSlideUpItem(
              delay: initialDelay,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      '关注 ${followingsIDs?.length ?? 0}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Expanded(
                    child: _buildListContainer(
                      context,
                      userIds: followingsIDs,
                      isFollowingList: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: FadeInSlideUpItem(
              delay: initialDelay + stagger,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      '粉丝 ${followersIDs?.length ?? 0}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Expanded(
                    child: _buildListContainer(
                      context,
                      userIds: followersIDs,
                      isFollowingList: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        RefreshIndicator(
          onRefresh: onRefreshTargetUser,
          child: (isLoadingTargetUser &&
                  (followingsIDs == null || followingsIDs!.isEmpty))
              ? _buildLoadingView("加载关注列表...")
              : _buildUserList(context, followingsIDs, isFollowingList: true),
        ),
        RefreshIndicator(
          onRefresh: onRefreshTargetUser,
          child: (isLoadingTargetUser &&
                  (followersIDs == null || followersIDs!.isEmpty))
              ? _buildLoadingView("加载粉丝列表...")
              : _buildUserList(context, followersIDs, isFollowingList: false),
        ),
      ],
    );
  }

  Widget _buildListContainer(
    BuildContext context, {
    required List<String>? userIds,
    required bool isFollowingList,
  }) {
    return RefreshIndicator(
      onRefresh: onRefreshTargetUser,
      child: _buildUserList(context, userIds, isFollowingList: isFollowingList),
    );
  }

  Widget _buildLoadingView(String message) {
    return LoadingWidget.inline(message: message);
  }

  Widget _buildUserList(BuildContext context, List<String>? userIds,
      {required bool isFollowingList}) {
    if (isLoadingTargetUser && (userIds == null || userIds.isEmpty)) {
      return _buildLoadingView(isFollowingList ? "加载关注列表中..." : "加载粉丝列表中...");
    }

    if (userIds?.isEmpty ?? true) {
      return FadeInSlideUpItem(
        child: Container(
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isFollowingList
                    ? Icons.person_search_outlined
                    : Icons.no_accounts_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                isFollowingList ? '还没有关注任何人' : '还没有粉丝',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              FunctionalTextButton(
                  onPressed: onRefreshTargetUser, label: '刷新看看'),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      itemCount: userIds!.length,
      itemBuilder: (context, index) {
        final String targetUserIdInList = userIds[index];

        return FadeInSlideUpItem(
          delay: Duration(milliseconds: 50 * index),
          duration: const Duration(milliseconds: 350),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: UserInfoBadge(
              key: ValueKey(targetUserIdInList),
              infoProvider: infoProvider,
              followService: followService,
              targetUserId: targetUserIdInList,
              currentUser: currentUser,
            ),
          ),
        );
      },
    );
  }
}

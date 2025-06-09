import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_list_view.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';

class FollowsLayout extends StatelessWidget {
  final User? currentUser;
  final bool isDesktopLayout;
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
    required this.isDesktopLayout,
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
    return isDesktopLayout
        ? _buildDesktopLayout(context)
        : _buildMobileLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
          const SizedBox(width: 20),
          Expanded(
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
              ? const LoadingWidget(message: "加载关注列表...")
              : _buildUserList(context, followingsIDs, isFollowingList: true),
        ),
        RefreshIndicator(
          onRefresh: onRefreshTargetUser,
          child: (isLoadingTargetUser &&
                  (followersIDs == null || followersIDs!.isEmpty))
              ? const LoadingWidget(message: "加载粉丝列表...")
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

  Widget _buildUserList(BuildContext context, List<String>? userIds,
      {required bool isFollowingList}) {
    if (isLoadingTargetUser && (userIds == null || userIds.isEmpty)) {
      return isFollowingList
          ? const LoadingWidget(message: "加载关注列表中...")
          : const LoadingWidget(message: "加载粉丝列表中...");
    }

    if (userIds?.isEmpty ?? true) {
      return Container(
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
            FunctionalTextButton(onPressed: onRefreshTargetUser, label: '刷新看看'),
          ],
        ),
      );
    }

    // 使用封装好的 AnimatedListView
    return AnimatedListView<String>(
      items: userIds!,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      itemBuilder: (context, index, targetUserIdInList) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: UserInfoBadge(
            key: ValueKey(targetUserIdInList),
            infoProvider: infoProvider,
            followService: followService,
            targetUserId: targetUserIdInList,
            currentUser: currentUser,
          ),
        );
      },
    );
  }
}

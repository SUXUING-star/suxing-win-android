// lib/widgets/components/screen/profile/responsive_follows_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../ui/image/safe_user_avatar.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../ui/buttons/follow_user_button.dart';

class ResponsiveFollowsLayout extends StatelessWidget {
  final TabController tabController;
  final List<Map<String, dynamic>> followings;
  final List<Map<String, dynamic>> followers;
  final bool isLoadingFollowings;
  final bool isLoadingFollowers;
  final bool followingsLoaded;
  final bool followersLoaded;
  final String? errorMessage;
  final String currentUserId;
  final Function() onRefresh;
  final Function({bool forceRefresh}) refreshFollowings;
  final Function({bool forceRefresh}) refreshFollowers;

  const ResponsiveFollowsLayout({
    Key? key,
    required this.tabController,
    required this.followings,
    required this.followers,
    required this.isLoadingFollowings,
    required this.isLoadingFollowers,
    required this.followingsLoaded,
    required this.followersLoaded,
    required this.errorMessage,
    required this.currentUserId,
    required this.onRefresh,
    required this.refreshFollowings,
    required this.refreshFollowers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 判断设备类型
    final isDesktop = DeviceUtils.isDesktop;
    final isTablet = DeviceUtils.isTablet(context);
    final isLandscape = DeviceUtils.isLandscape(context);

    // 桌面端或平板横屏使用并排布局
    if (isDesktop || (isTablet && isLandscape)) {
      return _buildDesktopLayout(context);
    } else {
      // 移动端使用标签页布局
      return _buildMobileLayout(context);
    }
  }

  // 桌面端布局 - 并排显示关注和粉丝列表
  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧 - 关注列表
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    '关注 ${followings.length}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  child: _buildListContainer(
                    context,
                    isLoading: isLoadingFollowings && !followingsLoaded,
                    users: followings,
                    isFollowing: true,
                    onRefresh: () => refreshFollowings(forceRefresh: true),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // 右侧 - 粉丝列表
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    '粉丝 ${followers.length}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  child: _buildListContainer(
                    context,
                    isLoading: isLoadingFollowers && !followersLoaded,
                    users: followers,
                    isFollowing: false,
                    onRefresh: () => refreshFollowers(forceRefresh: true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 移动端布局 - 使用TabBarView
  Widget _buildMobileLayout(BuildContext context) {
    if (errorMessage != null) {
      return _buildErrorView(context);
    }

    return TabBarView(
      controller: tabController,
      children: [
        // 关注列表
        RefreshIndicator(
          onRefresh: () async => await onRefresh(),
          child: isLoadingFollowings && !followingsLoaded
              ? _buildLoadingView()
              : _buildUserList(context, followings, isFollowing: true),
        ),
        // 粉丝列表
        RefreshIndicator(
          onRefresh: () async => await onRefresh(),
          child: isLoadingFollowers && !followersLoaded
              ? _buildLoadingView()
              : _buildUserList(context, followers, isFollowing: false),
        ),
      ],
    );
  }

  // 列表容器（带刷新功能）
  Widget _buildListContainer(
    BuildContext context, {
    required bool isLoading,
    required List<Map<String, dynamic>> users,
    required bool isFollowing,
    required VoidCallback onRefresh,
  }) {
    if (isLoading) {
      return _buildLoadingView();
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        return Future.value();
      },
      child: _buildUserList(context, users, isFollowing: isFollowing),
    );
  }

  // 加载中视图
  Widget _buildLoadingView() {
    return LoadingWidget.inline(
      message: '正在加载...',
      color: Colors.grey[600],
      size: 12,
    );
  }

  // 错误视图
  Widget _buildErrorView(BuildContext context) {
    return InlineErrorWidget(onRetry: onRefresh,errorMessage: '发生错误');
  }

  // 用户列表视图
  Widget _buildUserList(BuildContext context, List<Map<String, dynamic>> users,
      {required bool isFollowing}) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFollowing ? Icons.person_add_disabled : Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              isFollowing ? '暂无关注的用户' : '暂无粉丝',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            // 提供刷新按钮
            ElevatedButton(
              onPressed: () => isFollowing
                  ? refreshFollowings(forceRefresh: true)
                  : refreshFollowers(forceRefresh: true),
              child: Text('刷新'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final userId = user['id'] ?? user['_id'] ?? '';
        final username = user['username'] ?? '未知用户';
        final avatarUrl = user['avatar'];

        return Card(
          elevation: 1,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              NavigationUtils.pushNamed(
                context,
                AppRoutes.openProfile,
                arguments: userId,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SafeUserAvatar(
                    userId: userId,
                    avatarUrl: avatarUrl,
                    username: username,
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user['bio'] != null &&
                            user['bio'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              user['bio'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 不显示对自己的关注按钮
                  if (userId != currentUserId)
                    FollowUserButton(
                      userId: userId,
                      mini: true,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

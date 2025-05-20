// lib/widgets/components/screen/profile/responsive_follows_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../ui/badges/safe_user_avatar.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../ui/buttons/follow_user_button.dart';

class ResponsiveFollowsLayout extends StatelessWidget {
  final User? currentUser;
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
    super.key,
    required this.currentUser,
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
  });

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
    // 定义基础延迟和间隔
    const Duration initialDelay = Duration(milliseconds: 100);
    const Duration stagger = Duration(milliseconds: 150);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧 - 关注列表容器动画
          Expanded(
            child: FadeInSlideUpItem(
              // 添加动画
              delay: initialDelay, // 先出现
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题可以简单淡入，或者不加动画
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
                      // 传递加载状态，但列表项动画在内部处理
                      isLoading: isLoadingFollowings && !followingsLoaded,
                      users: followings,
                      isFollowing: true,
                      onRefresh: () => refreshFollowings(forceRefresh: true),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // 右侧 - 粉丝列表容器动画
          Expanded(
            child: FadeInSlideUpItem(
              // 添加动画
              delay: initialDelay + stagger, // 后出现
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
                      // 传递加载状态，但列表项动画在内部处理
                      isLoading: isLoadingFollowers && !followersLoaded,
                      users: followers,
                      isFollowing: false,
                      onRefresh: () => refreshFollowers(forceRefresh: true),
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

  // 移动端布局 - 使用TabBarView
  Widget _buildMobileLayout(BuildContext context) {
    // 错误视图的动画处理
    if (errorMessage != null) {
      return FadeInSlideUpItem(child: _buildErrorView(context)); // 包裹动画
    }

    // TabBarView 本身不加动画，动画在 children 内部
    return TabBarView(
      controller: tabController,
      children: [
        // 关注列表
        RefreshIndicator(
          onRefresh: () async => await onRefresh(),
          // *** 修改这里：根据加载状态显示 Loading 或 List ***
          child: isLoadingFollowings && !followingsLoaded // 初始加载状态
              ? _buildLoadingView() // 显示 Loading (带动画)
              : _buildUserList(context, followings,
                  isFollowing: true), // 显示列表 (内部带动画)
        ),
        // 粉丝列表
        RefreshIndicator(
          onRefresh: () async => await onRefresh(),
          // *** 修改这里：根据加载状态显示 Loading 或 List ***
          child: isLoadingFollowers && !followersLoaded // 初始加载状态
              ? _buildLoadingView() // 显示 Loading (带动画)
              : _buildUserList(context, followers,
                  isFollowing: false), // 显示列表 (内部带动画)
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
    // *** 修改这里：显示带动画的 Loading ***
    if (isLoading) {
      return _buildLoadingView(); // Loading 视图自带动画
    }

    // RefreshIndicator 包裹带动画的列表
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        return Future.value();
      },
      child: _buildUserList(context, users, isFollowing: isFollowing), // 列表自带动画
    );
  }

  // 加载中视图
  Widget _buildLoadingView() {
    return LoadingWidget.fullScreen(
      message: '正在加载...',
      size: 36,
    );
  }

  // 错误视图
  Widget _buildErrorView(BuildContext context) {
    return InlineErrorWidget(onRetry: onRefresh, errorMessage: '发生错误');
  }

// 用户列表视图
  Widget _buildUserList(BuildContext context, List<Map<String, dynamic>> users,
      {required bool isFollowing}) {
    // --- 空状态处理 ---
    if (users.isEmpty) {
      // *** 修改这里：为空状态添加动画 ***
      return FadeInSlideUpItem(
        // 包裹动画
        child: Opacity(
          // Opacity 可以保留或移除
          opacity: 0.9,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withSafeOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFollowing
                        ? Icons.person_add_disabled
                        : Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    isFollowing ? '暂无关注的用户' : '暂无粉丝',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 24),
                  FunctionalTextButton(
                      onPressed: () => isFollowing
                          ? refreshFollowings(forceRefresh: true)
                          : refreshFollowers(forceRefresh: true),
                      label: '刷新'),
                ],
              ),
            ),
          ),
        ),
      );
      // --- 结束空状态修改 ---
    }

    // --- 列表构建 ---
    // 添加 Key 帮助动画识别列表变化（虽然简单 delay 可能不需要严格的 Key）
    final listKey = ValueKey<String>(
        '${isFollowing ? 'following' : 'followers'}_${users.length}');

    return ListView.builder(
      key: listKey, // 应用 Key
      padding: EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final userId = user['id'] ?? user['_id'] ?? '';
        final username = user['username'] ?? '未知用户';
        final avatarUrl = user['avatar'];

        // *** 修改这里：为每个列表项 Card 添加动画 ***
        return FadeInSlideUpItem(
          // 使用 index 计算交错延迟
          delay: Duration(milliseconds: 50 * index),
          duration: Duration(milliseconds: 350),
          child: Card(
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
                        currentUser: currentUser,
                        targetUserId: userId,
                        mini: true,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );

        // --- 结束列表项修改 ---
      },
    );
  }
}

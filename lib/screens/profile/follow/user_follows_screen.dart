import 'package:flutter/material.dart';
import 'dart:async';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/follow/follows_layout.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';

class UserFollowsScreen extends StatefulWidget {
  final String userId;
  final String username;
  final bool initialShowFollowing;
  final UserFollowService followService;
  final AuthProvider authProvider;
  final UserInfoProvider infoProvider;
  final UserService userService;
  final WindowStateProvider windowStateProvider;

  const UserFollowsScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.authProvider,
    required this.followService,
    required this.infoProvider,
    required this.userService,
    required this.windowStateProvider,
    this.initialShowFollowing = true,
  });

  @override
  _UserFollowsScreenState createState() => _UserFollowsScreenState();
}

class _UserFollowsScreenState extends State<UserFollowsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<User>? _targetUserFuture;
  User? _lastSuccessfullyLoadedTargetUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialShowFollowing ? 0 : 1,
    );
    _loadTargetUserData();
  }

  void _loadTargetUserData({bool forceRefresh = false}) {
    if (_targetUserFuture == null || forceRefresh) {
      setState(() {
        _targetUserFuture = widget.userService
            .getUserInfoById(widget.userId, forceRefresh: forceRefresh);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handlePullToRefresh() async {
    _loadTargetUserData(forceRefresh: true);
    widget.authProvider.refreshUserState(); // 使用正确的函数名
  }

  @override
  Widget build(BuildContext context) {
    if (widget.authProvider.currentUser == null ||
        !widget.authProvider.isLoggedIn) {
      return const LoginPromptWidget();
    }

    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktopLayout = DeviceUtils.isDesktopInThisWidth(screenWidth);
        return FutureBuilder<User>(
          future: _targetUserFuture,
          builder: (context, targetUserSnapshot) {
            User? targetUserToDisplay = _lastSuccessfullyLoadedTargetUser;
            String appBarTitle = widget.username;
            Widget bodyContent;

            List<String> followingIDsForLayout = [];
            List<String> followerIDsForLayout = [];
            int tabFollowingCount = 0;
            int tabFollowerCount = 0;

            if (targetUserSnapshot.connectionState == ConnectionState.waiting &&
                targetUserToDisplay == null) {
              bodyContent = const FadeInItem(
                // 全屏加载组件
                child: LoadingWidget(
                  isOverlay: true,
                  message: "加载用户信息...",
                  overlayOpacity: 0.4,
                  size: 36,
                ),
              ); //
            } else if (targetUserSnapshot.hasError &&
                targetUserToDisplay == null) {
              bodyContent = CustomErrorWidget(
                errorMessage: '加载失败: ${targetUserSnapshot.error}',
                onRetry: _handlePullToRefresh,
              );
            } else {
              if (targetUserSnapshot.hasData) {
                _lastSuccessfullyLoadedTargetUser = targetUserSnapshot.data!;
                targetUserToDisplay = targetUserSnapshot.data!;
              }

              if (targetUserToDisplay == null) {
                bodyContent = CustomErrorWidget(
                  errorMessage: targetUserSnapshot.hasError
                      ? '加载失败: ${targetUserSnapshot.error}'
                      : '无法获取用户信息',
                  onRetry: _handlePullToRefresh,
                );
              } else {
                if (targetUserToDisplay.username.isNotEmpty) {
                  appBarTitle = targetUserToDisplay.username;
                }
                followingIDsForLayout = targetUserToDisplay.following;
                followerIDsForLayout = targetUserToDisplay.followers;
                tabFollowingCount = followingIDsForLayout.length;
                tabFollowerCount = followerIDsForLayout.length;

                bodyContent = FollowsLayout(
                  screenWidth: screenWidth,
                  currentUser: widget.authProvider.currentUser,
                  isDesktopLayout: isDesktopLayout,
                  viewingUserId: widget.userId,
                  tabController: _tabController,
                  followService: widget.followService,
                  infoProvider: widget.infoProvider,
                  followingsIDs: followingIDsForLayout,
                  followersIDs: followerIDsForLayout,
                  isLoadingTargetUser: targetUserSnapshot.connectionState ==
                      ConnectionState.waiting,
                  onRefreshTargetUser: _handlePullToRefresh,
                );
              }
            }

            if (targetUserToDisplay == null &&
                _lastSuccessfullyLoadedTargetUser != null) {
              tabFollowingCount =
                  _lastSuccessfullyLoadedTargetUser!.following.length;
              tabFollowerCount =
                  _lastSuccessfullyLoadedTargetUser!.followers.length;
              if (_lastSuccessfullyLoadedTargetUser!.username.isNotEmpty) {
                appBarTitle = _lastSuccessfullyLoadedTargetUser!.username;
              }
            }

            return Scaffold(
              appBar: CustomAppBar(
                title: appBarTitle,
                bottom: isDesktopLayout
                    ? null
                    : TabBar(
                        controller: _tabController,
                        tabs: [
                          Tab(text: '关注 $tabFollowingCount'),
                          Tab(text: '粉丝 $tabFollowerCount'),
                        ],
                      ),
              ),
              body: bodyContent,
            );
          },
        );
      },
    );
  }
}

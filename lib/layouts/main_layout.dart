// lib/layouts/main_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/app.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/services/main/announcement/announcement_service.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/services/main/linktool/link_tool_service.dart';
import 'package:suxingchahui/services/main/message/message_service.dart';
import 'package:suxingchahui/services/main/user/user_checkin_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/screens/home/home_screen.dart';
import 'package:suxingchahui/screens/game/list/games_list_screen.dart';
import 'package:suxingchahui/screens/linkstools/linkstools_screen.dart';
import 'package:suxingchahui/screens/activity/activity_feed_screen.dart';
import 'package:suxingchahui/screens/forum/forum_screen.dart';
import 'package:suxingchahui/screens/profile/profile_screen.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/layouts/mobile/top_navigation_bar.dart';
import 'package:suxingchahui/layouts/mobile/bottom_navigation_bar.dart';

class MainLayout extends StatefulWidget {
  final SidebarProvider sidebarProvider;
  final MessageService messageService;
  final AuthProvider authProvider;
  final UserService userService;
  final GameService gameService;
  final ForumService forumService;
  final UserActivityService activityService;
  final LinkToolService linkToolService;
  final UserFollowService followService;
  final AnnouncementService announcementService;
  final UserInfoProvider infoProvider;
  final InputStateService inputStateService;
  final UserCheckInService checkInService;
  final GameListFilterProvider gameListFilterProvider;
  const MainLayout({
    super.key,
    required this.sidebarProvider,
    required this.messageService,
    required this.authProvider,
    required this.activityService,
    required this.linkToolService,
    required this.forumService,
    required this.gameService,
    required this.userService,
    required this.followService,
    required this.infoProvider,
    required this.announcementService,
    required this.inputStateService,
    required this.checkInService,
    required this.gameListFilterProvider,
  });

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with RouteAware {
  bool _hasInitializedProviders = false;
  bool _hasInitializedScreens = false;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    if (!_hasInitializedProviders) {
      _hasInitializedProviders = true;
    }
    if (_hasInitializedProviders && !_hasInitializedScreens) {
      _screens = _buildScreens();
      _hasInitializedScreens = true;
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    _updateSubRouteStatus(false);
  }

  @override
  void didPop() {}

  @override
  void didPushNext() {
    _updateSubRouteStatus(true);
  }

  @override
  void didPopNext() {
    _updateSubRouteStatus(false);
  }

  void _updateSubRouteStatus(bool isActive) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.sidebarProvider.setSubRouteActive(isActive);
      }
    });
  }

  // _handleProfileTap 现在需要 isLoggedIn 参数
  void _handleProfileTap(bool isLoggedIn) {
    if (isLoggedIn) {
      widget.sidebarProvider.setCurrentIndex(5); // 假设 5 是 ProfileScreen 的索引
    } else {
      NavigationUtils.navigateToLogin(context);
    }
  }

  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        authProvider: widget.authProvider,
        gameService: widget.gameService,
        forumService: widget.forumService,
        followService: widget.followService,
        infoProvider: widget.infoProvider,
      ),
      GamesListScreen(
        authProvider: widget.authProvider,
        gameService: widget.gameService,
        gameListFilterProvider: widget.gameListFilterProvider,
      ),
      ForumScreen(
        authProvider: widget.authProvider,
        forumService: widget.forumService,
        followService: widget.followService,
        infoProvider: widget.infoProvider,
      ),
      ActivityFeedScreen(
        authProvider: widget.authProvider,
        activityService: widget.activityService,
        followService: widget.followService,
        infoProvider: widget.infoProvider,
        inputStateService: widget.inputStateService,
      ),
      LinksToolsScreen(
        authProvider: widget.authProvider,
        linkToolService: widget.linkToolService,
        inputStateService: widget.inputStateService,
      ),
      ProfileScreen(
        sidebarProvider: widget.sidebarProvider,
        authProvider: widget.authProvider,
        userService: widget.userService,
        inputStateService: widget.inputStateService,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop;

    return StreamBuilder<int>(
      // 最外层的 StreamBuilder 不变
      stream: widget.sidebarProvider.indexStream,
      initialData: widget.sidebarProvider.currentIndex,
      builder: (context, sidebarSnapshot) {
        final selectedIndex =
            sidebarSnapshot.data ?? widget.sidebarProvider.currentIndex;
        final validIndex = selectedIndex >= 0 && selectedIndex < _screens.length
            ? selectedIndex
            : 0;

        final bottomBar = CustomBottomNavigationBar(
          currentIndex: validIndex,
          onTap: (index) => widget.sidebarProvider.setCurrentIndex(index),
        );
        final indexedStack = IndexedStack(
          index: validIndex,
          children: _screens,
        );

        return StreamBuilder<bool>(
          stream: widget.authProvider.isLoggedInStream,
          initialData: widget.authProvider.isLoggedIn,
          builder: (context, isLoggedInSnapshot) {
            final bool isLoggedIn =
                isLoggedInSnapshot.data ?? widget.authProvider.isLoggedIn;
            // 主体 Scaffold 结构
            Widget mainContent = Scaffold(
              appBar: !isDesktop
                  ? TopNavigationBar(
                      announcementService: widget.announcementService,
                      messageService: widget.messageService,
                      checkInService: widget.checkInService,
                      authProvider: widget.authProvider, // TopNav 内部处理认证状态显示
                      onLogoTap: () {
                        widget.sidebarProvider.setCurrentIndex(0);
                      },
                      onProfileTap: () => _handleProfileTap(isLoggedIn),
                    )
                  : null,
              body: indexedStack,
              bottomNavigationBar: !isDesktop ? bottomBar : null,
            );
            return mainContent; // AuthProvider 不在加载状态，直接返回主内容
          },
        );
      },
    );
  }
}

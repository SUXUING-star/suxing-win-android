// lib/layouts/main_layout.dart

/// 该文件定义了 MainLayout 组件，它是应用的主体布局框架。
/// MainLayout 负责集成底部导航栏、顶部导航栏和主要内容区域，并管理不同屏幕之间的切换。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart'; // 导入游戏列表筛选 Provider
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态 Provider
import 'package:suxingchahui/providers/post/post_list_filter_provider.dart'; // 导入帖子列表筛选 Provider
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 导入用户信息 Provider
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart'; // 导入限速文件上传服务
import 'package:suxingchahui/services/main/activity/activity_service.dart'; // 导入活动服务
import 'package:suxingchahui/services/main/announcement/announcement_service.dart'; // 导入公告服务
import 'package:suxingchahui/services/main/forum/post_service.dart'; // 导入帖子服务
import 'package:suxingchahui/services/main/game/game_service.dart'; // 导入游戏服务
import 'package:suxingchahui/services/main/linktool/link_tool_service.dart'; // 导入链接工具服务
import 'package:suxingchahui/services/main/message/message_service.dart'; // 导入消息服务
import 'package:suxingchahui/services/main/user/user_checkin_service.dart'; // 导入用户签到服务
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 导入用户关注服务
import 'package:suxingchahui/services/main/user/user_service.dart'; // 导入用户服务
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/screens/home/home_screen.dart'; // 导入首页屏幕
import 'package:suxingchahui/screens/game/list/games_list_screen.dart'; // 导入游戏列表屏幕
import 'package:suxingchahui/screens/linkstools/linkstools_screen.dart'; // 导入链接工具屏幕
import 'package:suxingchahui/screens/activity/activity_feed_screen.dart'; // 导入活动动态屏幕
import 'package:suxingchahui/screens/forum/post_list_screen.dart'; // 导入帖子列表屏幕
import 'package:suxingchahui/screens/profile/profile_screen.dart'; // 导入个人资料屏幕
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart'; // 导入侧边栏 Provider
import 'package:suxingchahui/utils/device/device_utils.dart'; // 导入设备工具类
import 'package:suxingchahui/layouts/mobile/top_navigation_bar.dart'; // 导入移动端顶部导航栏
import 'package:suxingchahui/layouts/mobile/bottom_navigation_bar.dart'; // 导入移动端底部导航栏

/// `MainLayout` 类：应用的主体布局框架组件。
///
/// 该组件负责整合各种服务和 Provider，并根据导航状态显示不同的屏幕。
class MainLayout extends StatefulWidget {
  final SidebarProvider sidebarProvider; // 侧边栏 Provider
  final MessageService messageService; // 消息服务
  final AuthProvider authProvider; // 认证 Provider
  final UserService userService; // 用户服务
  final GameService gameService; // 游戏服务
  final PostService postService; // 帖子服务
  final ActivityService activityService; // 活动服务
  final LinkToolService linkToolService; // 链接工具服务
  final UserFollowService followService; // 用户关注服务
  final AnnouncementService announcementService; // 公告服务
  final UserInfoService infoService; // 用户信息 Provider
  final InputStateService inputStateService; // 输入状态 Provider
  final UserCheckInService checkInService; // 用户签到服务
  final GameListFilterProvider gameListFilterProvider; // 游戏列表筛选 Provider
  final PostListFilterProvider postListFilterProvider; // 帖子列表筛选 Provider
  final RateLimitedFileUpload fileUpload; // 限速文件上传服务
  final WindowStateProvider windowStateProvider; // 窗口管理

  /// 构造函数。
  ///
  /// [sidebarProvider]：侧边栏 Provider。
  /// [messageService]：消息服务。
  /// [authProvider]：认证 Provider。
  /// [activityService]：活动服务。
  /// [linkToolService]：链接工具服务。
  /// [postService]：帖子服务。
  /// [gameService]：游戏服务。
  /// [userService]：用户服务。
  /// [followService]：关注服务。
  /// [infoProvider]：用户信息 Provider。
  /// [announcementService]：公告服务。
  /// [inputStateService]：输入状态 Provider。
  /// [checkInService]：签到服务。
  /// [gameListFilterProvider]：游戏列表筛选 Provider。
  /// [postListFilterProvider]：帖子列表筛选 Provider。
  /// [fileUpload]：文件上传服务。
  /// [windowStateProvider]：文件上传服务。
  const MainLayout({
    super.key,
    required this.sidebarProvider,
    required this.messageService,
    required this.authProvider,
    required this.activityService,
    required this.linkToolService,
    required this.postService,
    required this.gameService,
    required this.userService,
    required this.followService,
    required this.infoService,
    required this.announcementService,
    required this.inputStateService,
    required this.checkInService,
    required this.gameListFilterProvider,
    required this.postListFilterProvider,
    required this.fileUpload,
    required this.windowStateProvider,
  });

  /// 创建状态。
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

/// `_MainLayoutState` 类：`MainLayout` 的状态管理。
///
/// 管理屏幕初始化、路由监听和子路由状态。
class _MainLayoutState extends State<MainLayout> {
  bool _hasInitializedProviders = false; // Provider 是否已初始化标记
  bool _hasInitializedScreens = false; // 屏幕是否已初始化标记
  late List<Widget> _screens; // 存储所有屏幕组件的列表

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedProviders) {
      _hasInitializedProviders = true; // 标记 Provider 已初始化
    }
    if (_hasInitializedProviders && !_hasInitializedScreens) {
      _screens = _buildScreens(); // 构建屏幕列表
      _hasInitializedScreens = true; // 标记屏幕已初始化
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 处理个人资料点击。
  ///
  /// [isLoggedIn]：当前用户是否已登录。
  /// 根据登录状态导航到个人资料屏幕或登录屏幕。
  void _handleProfileTap(bool isLoggedIn) {
    if (isLoggedIn) {
      widget.sidebarProvider.setCurrentIndex(5); // 导航到个人资料屏幕（索引 5）
    } else {
      NavigationUtils.navigateToLogin(context); // 导航到登录屏幕
    }
  }

  /// 构建所有应用程序屏幕的列表。
  ///
  /// 返回一个包含所有屏幕组件的列表。
  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        windowStateProvider: widget.windowStateProvider,
        authProvider: widget.authProvider,
        gameService: widget.gameService,
        postService: widget.postService,
        followService: widget.followService,
        infoService: widget.infoService,
      ),
      GamesListScreen(
        authProvider: widget.authProvider,
        gameService: widget.gameService,
        gameListFilterProvider: widget.gameListFilterProvider,
        windowStateProvider: widget.windowStateProvider,
      ),
      PostListScreen(
        authProvider: widget.authProvider,
        postService: widget.postService,
        followService: widget.followService,
        infoService: widget.infoService,
        postListFilterProvider: widget.postListFilterProvider,
        windowStateProvider: widget.windowStateProvider,
      ),
      ActivityFeedScreen(
        authProvider: widget.authProvider,
        activityService: widget.activityService,
        followService: widget.followService,
        infoService: widget.infoService,
        inputStateService: widget.inputStateService,
        windowStateProvider: widget.windowStateProvider,
      ),
      LinksToolsScreen(
        authProvider: widget.authProvider,
        linkToolService: widget.linkToolService,
        inputStateService: widget.inputStateService,
        windowStateProvider: widget.windowStateProvider,
      ),
      ProfileScreen(
        sidebarProvider: widget.sidebarProvider,
        authProvider: widget.authProvider,
        userService: widget.userService,
        inputStateService: widget.inputStateService,
        fileUpload: widget.fileUpload,
        windowStateProvider: widget.windowStateProvider,
        infoService: widget.infoService,
      ),
    ];
  }

  /// 构建应用程序的主布局界面。
  ///
  /// 该方法根据设备类型（桌面或移动端）和导航状态，
  /// 显示不同的顶部栏、底部导航栏和 IndexedStack 管理的屏幕内容。
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop; // 判断是否为桌面平台

    // print("测试widgetbuild有没有被调用");
    // print("主导航的index发生变化没有？？");
    // print(widget.sidebarProvider.currentIndex);

    return StreamBuilder<int>(
      stream: widget.sidebarProvider.indexStream, // 监听侧边栏索引流
      initialData: widget.sidebarProvider.currentIndex, // 初始侧边栏索引
      builder: (context, sidebarSnapshot) {
        final selectedIndex = sidebarSnapshot.data ??
            widget.sidebarProvider.currentIndex; // 获取当前选中索引
        final validIndex = selectedIndex >= 0 && selectedIndex < _screens.length
            ? selectedIndex
            : 0; // 确保索引有效

        final bottomBar = CustomBottomNavigationBar(
          currentIndex: validIndex, // 底部导航栏当前索引
          onTap: (index) =>
              widget.sidebarProvider.setCurrentIndex(index), // 底部导航栏点击回调
        );
        final indexedStack = IndexedStack(
          index: validIndex, // IndexedStack 当前索引
          children: _screens, // IndexedStack 子组件列表
        );

        return StreamBuilder<bool>(
          stream: widget.authProvider.isLoggedInStream, // 监听认证状态流
          initialData: widget.authProvider.isLoggedIn, // 初始认证状态
          builder: (context, isLoggedInSnapshot) {
            final bool isLoggedIn = isLoggedInSnapshot.data ??
                widget.authProvider.isLoggedIn; // 获取当前登录状态

            Widget mainContent = Scaffold(
              appBar: !isDesktop // 非桌面平台显示顶部导航栏
                  ? TopNavigationBar(
                      announcementService: widget.announcementService,
                      messageService: widget.messageService,
                      checkInService: widget.checkInService,
                      authProvider: widget.authProvider,
                      onLogoTap: () {
                        widget.sidebarProvider
                            .setCurrentIndex(0); // 点击 Logo 导航到首页
                      },
                      onProfileTap: () =>
                          _handleProfileTap(isLoggedIn), // 点击个人资料回调
                    )
                  : null, // 桌面平台不显示顶部导航栏
              body: indexedStack, // 主体内容为 IndexedStack
              bottomNavigationBar:
                  !isDesktop ? bottomBar : null, // 非桌面平台显示底部导航栏
            );
            return mainContent; // 返回主内容组件
          },
        );
      },
    );
  }
}

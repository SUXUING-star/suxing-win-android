// lib/layouts/main_layout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 引入 Provider
import 'package:suxingchahui/app.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 可能需要用于导航到登录
import '../screens/home/home_screen.dart';
import '../screens/game/list/games_list_screen.dart';
import '../screens/linkstools/linkstools_screen.dart';
import '../screens/activity/activity_feed_screen.dart';
import '../screens/forum/forum_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../providers/auth/auth_provider.dart';
import '../providers/navigation/sidebar_provider.dart'; // *** 引入 SidebarProvider ***
import '../services/main/update/update_service.dart';
import '../services/main/user/user_ban_service.dart';
import '../services/main/announcement/announcement_service.dart';
import '../services/main/network/network_manager.dart';
import '../utils/device/device_utils.dart';
import 'mobile/top_navigation_bar.dart';
import 'mobile/bottom_navigation_bar.dart';
import '../widgets/components/dialogs/update/force_update_dialog.dart';
import '../widgets/components/dialogs/ban/user_ban_dialog.dart';
import '../widgets/components/dialogs/announcement/announcement_dialog.dart';

// *** 移除 GlobalKey 和静态方法 ***
class MainLayout extends StatefulWidget {
  // *** 构造函数不再需要 key ***
  const MainLayout({super.key});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with RouteAware {
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(),
      GamesListScreen(),
      ForumScreen(),
      ActivityFeedScreen(),
      LinksToolsScreen(),
      ProfileScreen(), // 索引 5
    ];

    // *** 移除检查 _pendingNavigationIndex 的逻辑 ***

    // 应用启动时检查更新、公告和封禁状态 (保持不变)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // 检查 mounted 状态
      _checkForUpdates();
      _checkBanStatus();
      _checkAnnouncements();
      _ensureNetworkManagerInitialized();
      _updateSubRouteStatus(false); // Set initial state
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to RouteObserver in didChangeDependencies
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    //print("MainLayout: Subscribed to RouteObserver");
  }

  @override
  void dispose() {
    // Unsubscribe from RouteObserver in dispose
    routeObserver.unsubscribe(this);
    //print("MainLayout: Unsubscribed from RouteObserver");
    super.dispose();
  }

  /// Called when the current route has been pushed.
  @override
  void didPush() {
    _updateSubRouteStatus(
        false); // Assume becoming visible means no sub-route initially
  }

  /// Called when the current route has been popped off.
  @override
  void didPop() {}

  /// Called when a new route has been pushed, and the current route is no longer visible.
  @override
  void didPushNext() {
    _updateSubRouteStatus(true);
  }

  /// Called when the top route has been popped off, and the current route is visible again.
  @override
  void didPopNext() {
    //print("MainLayout: didPopNext - Route popped, MainLayout visible AGAIN.");
    // We are returning to MainLayout, so no sub-route is active anymore
    _updateSubRouteStatus(false);
  }

  // Helper method to update the provider
  void _updateSubRouteStatus(bool isActive) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if still mounted before accessing provider
        Provider.of<SidebarProvider>(context, listen: false)
            .setSubRouteActive(isActive);
      }
    });
  }

  // 确保网络管理器已初始化
  Future<void> _ensureNetworkManagerInitialized() async {
    try {
      final networkManager =
          Provider.of<NetworkManager>(context, listen: false);
      if (!networkManager.isInitialized) {
        await networkManager.init();
      }
    } catch (e) {
      print('确保网络管理器初始化时出错: $e');
    }
  }

  // 检查公告方法
  Future<void> _checkAnnouncements() async {
    try {
      if (!mounted) return;

      final announcementService =
          Provider.of<AnnouncementService>(context, listen: false);

      // 确保服务已初始化
      if (!announcementService.isInitialized) {
        await announcementService.init();
      }

      // 获取公告
      await announcementService.getActiveAnnouncements();

      // 显示未读公告 (如果有)
      final unreadAnnouncements = announcementService.getUnreadAnnouncements();
      if (unreadAnnouncements.isNotEmpty && mounted) {
        showAnnouncementDialog(
          context,
          unreadAnnouncements.first,
        );
      }
    } catch (e) {
      print('Check announcements error: $e');
    }
  }

  // 检查封禁状态 (保持不变)
  Future<void> _checkBanStatus() async {
    try {
      final banService = context.read<UserBanService>();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUserId;
      final isLogged = authProvider.isLoggedIn;
      if (userId != null && isLogged) {
        final ban = await banService.checkUserBan(userId);
        if (ban != null && mounted) {
          // 显示封禁对话框

          UserBanDialog.show(ban: ban, context: context);
        }
      }
    } catch (e) {
      print('Check ban status error: $e');
    }
  }

  // 检查更新 (保持不变)
  Future<void> _checkForUpdates() async {
    if (!mounted) return;

    final updateService = Provider.of<UpdateService>(context, listen: false);
    await updateService.checkForUpdates();

    // 如果有强制更新并且界面还在挂载状态，显示对话框
    if (mounted && updateService.updateAvailable && updateService.forceUpdate) {
      ForceUpdateDialog.show(
        context: context,
        currentVersion: updateService.latestVersion ?? '',
        latestVersion: updateService.latestVersion ?? '',
        updateMessage: updateService.updateMessage,
        changelog: updateService.changelog,
        updateUrl: updateService.updateUrl ?? '',
      );
    }
  }

  void _handleProfileTap() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      Provider.of<SidebarProvider>(context, listen: false).setCurrentIndex(5);
    } else {
      NavigationUtils.navigateToLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop;

    // *** 监听 SidebarProvider 获取当前选中的索引 ***
    final selectedIndex = context.watch<SidebarProvider>().currentIndex;

    // 确保索引在 _screens 列表的有效范围内
    final validIndex = selectedIndex >= 0 && selectedIndex < _screens.length
        ? selectedIndex
        : 0; // 如果索引无效，默认显示第一个页面 (Home)


    return Scaffold(
      // 移动平台显示顶部导航栏 (逻辑不变，但 onTap 回调需要修改)
      appBar: !isDesktop
          ? TopNavigationBar(
              onLogoTap: () {
                // *** 点击 Logo，更新 SidebarProvider 回到首页 (索引 0) ***
                Provider.of<SidebarProvider>(context, listen: false)
                    .setCurrentIndex(0);
              },
              onProfileTap: _handleProfileTap, // 使用更新后的 _handleProfileTap
            )
          : null,
      body: Stack(
        children: [
          // *** 使用从 Provider 获取的 validIndex 来决定显示哪个 Screen ***
          // 使用 IndexedStack 保持页面状态
          IndexedStack(
            index: validIndex,
            children: _screens,
          ),
        ],
      ),
      // 移动平台显示底部导航栏 (逻辑不变，但 onTap 回调需要修改)
      bottomNavigationBar: !isDesktop
          ? CustomBottomNavigationBar(
              // *** 使用从 Provider 获取的 validIndex 作为当前索引 ***
              currentIndex: validIndex,
              // *** 点击底部导航项时，更新 SidebarProvider ***
              onTap: (index) =>
                  Provider.of<SidebarProvider>(context, listen: false)
                      .setCurrentIndex(index),
            )
          : null,
    );
  }
}

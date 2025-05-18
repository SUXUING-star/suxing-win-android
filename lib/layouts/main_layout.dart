// lib/layouts/main_layout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/app.dart';
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
  const MainLayout({super.key});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with RouteAware {
  late List<Widget> _screens;
  bool _hasInitializedDependencies = false;
  late final AuthProvider _authProvider;
  late final SidebarProvider _sidebarProvider;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    if (!_hasInitializedDependencies) {
      _sidebarProvider = Provider.of<SidebarProvider>(context, listen: false);
      _hasInitializedDependencies = true;
    }
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
    _updateSubRouteStatus(false);
  }

  // Helper method to update the provider
  void _updateSubRouteStatus(bool isActive) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if still mounted before accessing provider
        _sidebarProvider.setSubRouteActive(isActive);
      }
    });
  }

  void _handleProfileTap() {
    if (_authProvider.isLoggedIn) {
      _sidebarProvider.setCurrentIndex(5);
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
              isLoggedIn: _authProvider.isLoggedIn,
              onLogoTap: () {
                // *** 点击 Logo，更新 SidebarProvider 回到首页 (索引 0) ***
                _sidebarProvider.setCurrentIndex(0);
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
              onTap: (index) => _sidebarProvider.setCurrentIndex(index),
            )
          : null,
    );
  }
}

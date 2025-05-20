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
  bool _hasInitializedProviders = false;
  late final SidebarProvider _sidebarProvider;

  List<Widget> _buildScreens(AuthProvider authProvider) {
    return [
      HomeScreen(
        authProvider: authProvider,
      ),
      GamesListScreen(
        authProvider: authProvider,
      ),
      ForumScreen(
        authProvider: authProvider,
      ),
      ActivityFeedScreen(
        authProvider: authProvider,
      ),
      LinksToolsScreen(
        authProvider: authProvider,
      ),
      ProfileScreen(
        authProvider: authProvider,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    if (!_hasInitializedProviders) {
      _sidebarProvider = Provider.of<SidebarProvider>(context, listen: false);
      // AuthProvider 不再在这里获取，会在 build 方法中 watch
      _hasInitializedProviders = true;
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
        _sidebarProvider.setSubRouteActive(isActive);
      }
    });
  }

  // _handleProfileTap 现在需要 isLoggedIn 参数
  void _handleProfileTap(bool isLoggedIn) {
    if (isLoggedIn) {
      _sidebarProvider.setCurrentIndex(5); // 假设 5 是 ProfileScreen 的索引
    } else {
      NavigationUtils.navigateToLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop;

    final authProvider = context.watch<AuthProvider>();
    final bool isLoggedIn = authProvider.isLoggedIn;

    final selectedIndex = context.watch<SidebarProvider>().currentIndex;

    final screens = _buildScreens(authProvider);

    final validIndex = selectedIndex >= 0 && selectedIndex < screens.length
        ? selectedIndex
        : 0;

    return Scaffold(
      appBar: !isDesktop
          ? TopNavigationBar(
              authProvider: authProvider,
              onLogoTap: () {
                _sidebarProvider.setCurrentIndex(0);
              },
              onProfileTap: () =>
                  _handleProfileTap(isLoggedIn), // 把 isLoggedIn 传给处理函数
            )
          : null,
      body: IndexedStack(
        index: validIndex,
        children: screens,
      ),
      bottomNavigationBar: !isDesktop
          ? CustomBottomNavigationBar(
              currentIndex: validIndex,
              onTap: (index) => _sidebarProvider.setCurrentIndex(index),
            )
          : null,
    );
  }
}

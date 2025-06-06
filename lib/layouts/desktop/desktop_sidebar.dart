// lib/widgets/layouts/desktop/desktop_sidebar.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'desktop_frame_layout.dart.dart';
import 'desktop_sidebar_nav_item.dart';
import 'desktop_sidebar_user_profile.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';

class DesktopSidebar extends StatelessWidget {
  final Widget child;
  final SidebarProvider sidebarProvider;
  final AuthProvider authProvider;
  static const double _sidebarWidth = 70.0;
  double get sidebarWidth => _sidebarWidth;

  const DesktopSidebar({
    super.key,
    required this.sidebarProvider,
    required this.child,
    required this.authProvider,
  });


  static const iconPath = GlobalConstants.appIcon;
  static const List<Color> sideBarColors = [
    Color(0xFFD8FFEF),
    Color(0x000000ff),
  ];

  List<Map<String, dynamic>> _getNavItems() {
    return [
      {'icon': Icons.home_rounded, 'label': '首页', 'index': 0},
      {'icon': Icons.games_rounded, 'label': '游戏', 'index': 1},
      {'icon': Icons.forum_rounded, 'label': '论坛', 'index': 2},
      {'icon': Icons.rocket_launch, 'label': '动态', 'index': 3},
      {'icon': Icons.link_rounded, 'label': '外部', 'index': 4},
    ];
  }

  // 构建导航菜单，现在通过 StreamBuilder 监听 currentIndex
  Widget _buildSidebarNavigation(BuildContext context) {
    return StreamBuilder<int>(
      stream: sidebarProvider.indexStream, // 监听 indexStream
      initialData: sidebarProvider.currentIndex, // 初始值
      builder: (context, snapshot) {
        final int currentSidebarIndex =
            snapshot.data ?? sidebarProvider.currentIndex;
        return ListView(
          padding: EdgeInsets.symmetric(vertical: 2),
          children: _getNavItems()
              .map((item) => DesktopSidebarNavItem(
                    icon: item['icon'],
                    label: item['label'],
                    index: item['index'],
                    isSelected: currentSidebarIndex == item['index'],
                    onTap: () => _navigateToMainScreen(
                      context,
                      item['index'],
                    ), // 传递 actions 实例
                  ))
              .toList(),
        );
      },
    );
  }

  // 导航到指定页面
  void _navigateToMainScreen(BuildContext context, int index) {
    NavigationUtils.navigateToHome(sidebarProvider, context, tabIndex: index);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop;

    return Row(
      children: [
        Container(
          width: _sidebarWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [...sideBarColors],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withSafeOpacity(0.1),
                blurRadius: 8,
                offset: Offset(2, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: DesktopFrameLayout.kDesktopTitleBarHeight),
              child: Column(
                children: [
                  StreamBuilder<bool>(
                    stream: sidebarProvider.subRouteActiveStream, // 监听新的 stream
                    initialData: sidebarProvider.isSubRouteActive, // 设置初始值
                    builder: (context, snapshot) {
                      final bool isSubRouteActive =
                          snapshot.data ?? sidebarProvider.isSubRouteActive;
                      if (isDesktop && isSubRouteActive) {
                        return IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black54),
                          iconSize: 20,
                          tooltip: '返回',
                          onPressed: () {
                            NavigationUtils.pop(context);
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  DesktopSidebarUserProfile(
                    onProfileTap: () => _navigateToMainScreen(context, 5),
                    authProvider: authProvider,
                  ),
                  Expanded(
                    child: _buildSidebarNavigation(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(
                      color: Colors.white.withSafeOpacity(0.3),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: child,
        ),
      ],
    );
  }
}

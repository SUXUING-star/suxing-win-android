// lib/widgets/layouts/desktop/desktop_sidebar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/wrapper/platform_wrapper.dart';
import '../../providers/navigation/sidebar_provider.dart';
import 'desktop_sidebar_nav_item.dart';
import 'desktop_sidebar_user_profile.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';

class DesktopSidebar extends StatelessWidget {
  final Widget child;
  static const double _sidebarWidth = 70.0;
  static const sidebarWidth = _sidebarWidth;

  const DesktopSidebar({
    super.key,
    required this.child,
  });

  static const iconPath = 'assets/images/icons';
  static const List<Color> sideBarColors = [
    Color(0xFFD8FFEF),
    Color(0x000000ff),
  ];

  // 导航菜单项列表
  List<Map<String, dynamic>> _getNavItems() {
    return [
      {'icon': Icons.home_rounded, 'label': '首页', 'index': 0},
      {'icon': Icons.games_rounded, 'label': '游戏', 'index': 1},
      {'icon': Icons.forum_rounded, 'label': '论坛', 'index': 2},
      {'icon': Icons.rocket_launch, 'label': '动态', 'index': 3},
      {'icon': Icons.link_rounded, 'label': '外部', 'index': 4},
    ];
  }

  // 构建导航菜单
  Widget _buildSidebarNavigation(BuildContext context) {
    final currentSidebarIndex =
        Provider.of<SidebarProvider>(context).currentIndex;
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 2),
      children: _getNavItems()
          .map((item) => DesktopSidebarNavItem(
                icon: item['icon'],
                label: item['label'],
                index: item['index'],
                isSelected: currentSidebarIndex == item['index'],
                onTap: () => _navigateToMainScreen(context, item['index']),
              ))
          .toList(),
    );
  }

  // 导航到指定页面
  void _navigateToMainScreen(BuildContext context, int index) {
    Provider.of<SidebarProvider>(context, listen: false).setCurrentIndex(index);
    NavigationUtils.navigateToHome(context, tabIndex: index);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool canGoBack = Navigator.canPop(context);
    //print("cangoback: $canGoBack");
    // 侧边栏宽度

    return Row(
      children: [
        // 左侧边栏
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(2, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: PlatformWrapper.kDesktopTitleBarHeight),
              child: Consumer<SidebarProvider>(
                // <--- Consume SidebarProvider
                builder: (context, sidebarState, _) {
                  final bool isSubRouteActive = sidebarState.isSubRouteActive;
                  return Column(
                    children: [
                      if (isDesktop &&
                          isSubRouteActive) // <-- Use the new state
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black54),
                          iconSize: 20,
                          tooltip: '返回',
                          onPressed: () {
                            // Pop using NavigationUtils (which should update state via RouteObserver)
                            NavigationUtils.pop(context);
                          },
                        )
                      else // Placeholder to prevent layout jumps
                        SizedBox.shrink(),
                      // 用户资料
                      DesktopSidebarUserProfile(
                        onProfileTap: () => _navigateToMainScreen(context, 5),
                      ),

                      // 导航菜单（可滚动）
                      Expanded(
                        child: _buildSidebarNavigation(context),
                      ),

                      // 分隔线
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Divider(
                          color: Colors.white.withOpacity(0.3),
                          height: 1,
                        ),
                      ),
                    ],
                  );
                },
              ),
              // --- End Consumer ---
            ),
          ),
        ),

        // 主内容区域
        Expanded(
          child: child,
        ),
      ],
    );
  }
}

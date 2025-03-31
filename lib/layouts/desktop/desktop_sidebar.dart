// lib/widgets/layouts/desktop/desktop_sidebar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation/sidebar_provider.dart';
import '../../app.dart';
import '../main_layout.dart';
import 'desktop_sidebar_nav_item.dart';
import 'desktop_sidebar_buttons.dart';
import 'desktop_sidebar_user_profile.dart';

class DesktopSidebar extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const DesktopSidebar({
    Key? key,
    required this.child,
    this.currentIndex = 0,
  }) : super(key: key);

  static const iconPath = 'assets/images/icons';

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
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 16),
      children: _getNavItems()
          .map((item) => DesktopSidebarNavItem(
        icon: item['icon'],
        label: item['label'],
        index: item['index'],
        isSelected: currentIndex == item['index'],
        onTap: () => _navigateToMainScreen(context, item['index']),
      ))
          .toList(),
    );
  }

  // 导航到指定页面
  void _navigateToMainScreen(BuildContext context, int index) {
    print("桌面侧边栏: 导航到标签索引 $index");

    // 更新侧边栏提供者
    Provider.of<SidebarProvider>(context, listen: false).setCurrentIndex(index);

    // 设置主布局索引
    MainLayout.navigateTo(index);

    // 使用全局导航器
    final navigator = mainNavigatorKey.currentState;

    if (navigator != null) {
      // 返回到首页
      navigator.popUntil((route) => route.isFirst);
      print("桌面侧边栏: 已返回到主页面");
    } else {
      print("桌面侧边栏: 未找到导航器实例");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 侧边栏宽度
    const double sidebarWidth = 80.0;

    return Row(
      children: [
        // 左侧边栏
        Container(
          width: sidebarWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF6AB7F0),
                Color(0xFF4E9DE3),
              ],
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
            child: Column(
              children: [
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

                // 移动端按钮区域
                DesktopSidebarMobileButtons(),


              ],
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
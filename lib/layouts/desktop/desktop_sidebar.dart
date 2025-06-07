// lib/layouts/desktop/desktop_sidebar.dart

/// 该文件定义了 DesktopSidebar 组件，一个用于桌面应用的侧边栏布局。
/// DesktopSidebar 包含导航项、用户资料区域和返回按钮。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/constants/global_constants.dart'; // 导入全局常量
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart'; // 导入侧边栏 Provider
import 'desktop_frame_layout.dart'; // 导入桌面框架布局
import 'desktop_sidebar_nav_item.dart'; // 导入侧边栏导航项
import 'desktop_sidebar_user_profile.dart'; // 导入侧边栏用户资料
import 'package:suxingchahui/utils/device/device_utils.dart'; // 导入设备工具类

/// `DesktopSidebar` 类：桌面应用的侧边栏布局组件。
///
/// 该组件提供侧边栏导航、用户资料显示和子路由返回功能。
class DesktopSidebar extends StatelessWidget {
  final Widget child; // 侧边栏右侧的主要内容区域
  final SidebarProvider sidebarProvider; // 侧边栏 Provider 实例
  final AuthProvider authProvider; // 认证 Provider 实例
  static const double _sidebarWidth = 70.0; // 侧边栏宽度
  /// 获取侧边栏宽度。
  double get sidebarWidth => _sidebarWidth;

  /// 构造函数。
  ///
  /// [sidebarProvider]：侧边栏 Provider。
  /// [child]：主要内容。
  /// [authProvider]：认证 Provider。
  const DesktopSidebar({
    super.key,
    required this.sidebarProvider,
    required this.child,
    required this.authProvider,
  });

  static const iconPath = GlobalConstants.appIcon; // 应用图标路径

  /// 构建侧边栏导航菜单。
  ///
  /// [context]：Build 上下文。
  /// 该方法通过 StreamBuilder 监听 `currentIndex` 变化以更新选中项。
  Widget _buildSidebarNavigation(BuildContext context) {
    return StreamBuilder<int>(
      stream: sidebarProvider.indexStream, // 监听索引流
      initialData: sidebarProvider.currentIndex, // 初始索引
      builder: (context, snapshot) {
        final int currentSidebarIndex =
            snapshot.data ?? sidebarProvider.currentIndex; // 获取当前侧边栏索引
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 2), // 列表内边距
          children: GlobalConstants.defaultSideBarNavItems()
              .map((item) => DesktopSidebarNavItem(
                    icon: item['icon'], // 导航项图标
                    label: item['label'], // 导航项标签
                    index: item['index'], // 导航项索引
                    isSelected: currentSidebarIndex == item['index'], // 是否选中
                    onTap: () => _navigateToMainScreen(
                      context,
                      item['index'],
                    ), // 点击导航到主屏幕
                  ))
              .toList(),
        );
      },
    );
  }

  /// 导航到指定的主屏幕页面。
  ///
  /// [context]：Build 上下文。
  /// [index]：要导航到的页面索引。
  void _navigateToMainScreen(BuildContext context, int index) {
    NavigationUtils.navigateToHome(sidebarProvider, context,
        tabIndex: index); // 导航到主页
  }

  /// 构建桌面侧边栏布局。
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop; // 判断是否为桌面平台

    return Row(
      children: [
        Container(
          width: _sidebarWidth, // 侧边栏宽度
          height: double.infinity, // 填充父级高度
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // 渐变背景
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [...GlobalConstants.defaultSideBarColors],
            ),
            boxShadow: [
              // 阴影
              BoxShadow(
                color: Colors.black.withSafeOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: DesktopFrameLayout.kDesktopTitleBarHeight), // 顶部填充标题栏高度
              child: Column(
                children: [
                  StreamBuilder<bool>(
                    stream: sidebarProvider.subRouteActiveStream, // 监听子路由激活状态流
                    initialData: sidebarProvider.isSubRouteActive, // 初始子路由激活状态
                    builder: (context, snapshot) {
                      final bool isSubRouteActive = snapshot.data ??
                          sidebarProvider.isSubRouteActive; // 获取子路由激活状态
                      if (isDesktop && isSubRouteActive) {
                        // 桌面平台且子路由激活时显示返回按钮
                        return IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.black54), // 返回图标
                          iconSize: 20, // 图标大小
                          tooltip: '返回', // 提示
                          onPressed: () {
                            NavigationUtils.pop(context); // 返回上一页
                          },
                        );
                      }
                      return const SizedBox.shrink(); // 否则隐藏
                    },
                  ),
                  DesktopSidebarUserProfile(
                    onProfileTap: () =>
                        _navigateToMainScreen(context, 5), // 点击用户资料导航到个人中心
                    authProvider: authProvider, // 认证 Provider
                  ),
                  Expanded(
                    child: _buildSidebarNavigation(context), // 导航菜单
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16.0), // 水平填充
                    child: Divider(
                      color: Colors.white.withSafeOpacity(0.3), // 分隔线颜色
                      height: 1, // 分隔线高度
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: child, // 主要内容区域
        ),
      ],
    );
  }
}

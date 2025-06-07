// lib/layouts/mobile/bottom_navigation_bar.dart

/// 该文件定义了 CustomBottomNavigationBar 组件，一个自定义的底部导航栏。
/// CustomBottomNavigationBar 根据设备屏幕方向适配其样式和导航项。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/utils/device/device_utils.dart'; // 导入设备工具类

/// `CustomBottomNavigationBar` 类：自定义底部导航栏组件。
///
/// 该组件根据设备是否为 Android 横屏模式调整其内边距、字体大小和图标大小。
class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex; // 当前选中项的索引
  final Function(int) onTap; // 导航项点击回调

  /// 构造函数。
  ///
  /// [currentIndex]：当前索引。
  /// [onTap]：点击回调。
  const CustomBottomNavigationBar(
      {super.key, required this.currentIndex, required this.onTap});

  /// 构建自定义底部导航栏。
  @override
  Widget build(BuildContext context) {
    final bool isAndroidLandscape =
        DeviceUtils.isAndroid && DeviceUtils.isLandscape(context); // 判断是否为安卓横屏

    final verticalPadding = isAndroidLandscape ? 4.0 : 8.0; // 根据横屏模式调整垂直内边距

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // 背景色
        boxShadow: [
          // 阴影
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05), // 阴影颜色
            blurRadius: 20, // 模糊半径
            offset: const Offset(0, -5), // 偏移量
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 8, vertical: verticalPadding), // 水平与垂直内边距
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20), // 圆角
            child: BottomNavigationBar(
              currentIndex: currentIndex, // 当前选中项
              elevation: 0, // 阴影高度
              backgroundColor: Colors.grey[50], // 背景色
              type: BottomNavigationBarType.fixed, // 导航栏类型
              selectedItemColor: const Color(0xFF2979FF), // 选中项颜色
              unselectedItemColor: Colors.grey[400], // 未选中项颜色
              selectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500, // 选中标签字体粗细
                fontSize: isAndroidLandscape ? 10 : 12, // 选中标签字体大小
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: isAndroidLandscape ? 10 : 12, // 未选中标签字体大小
              ),
              items: [
                // 导航项列表
                _buildNavItem(Icons.home_rounded, '首页', isAndroidLandscape),
                _buildNavItem(Icons.games_rounded, '游戏', isAndroidLandscape),
                _buildNavItem(Icons.forum_rounded, '帖子', isAndroidLandscape),
                _buildNavItem(Icons.rocket_launch, '动态', isAndroidLandscape),
                _buildNavItem(Icons.link_rounded, '外部', isAndroidLandscape),
                _buildNavItem(Icons.person_rounded, '我的', isAndroidLandscape),
              ],
              onTap: onTap, // 导航项点击回调
            ),
          ),
        ),
      ),
    );
  }

  /// 构建单个底部导航栏项。
  ///
  /// [icon]：导航项图标。
  /// [label]：导航项标签。
  /// [isAndroidLandscape]：是否为安卓横屏模式。
  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, bool isAndroidLandscape) {
    final padding = isAndroidLandscape ? 6.0 : 8.0; // 内边距
    final iconSize = isAndroidLandscape ? 20.0 : 24.0; // 图标大小

    return BottomNavigationBarItem(
      icon: MouseRegion(
        cursor: SystemMouseCursors.click, // 鼠标悬停显示点击光标
        child: Icon(icon, size: iconSize), // 图标
      ),
      activeIcon: Container(
        padding: EdgeInsets.all(padding), // 内边距
        decoration: BoxDecoration(
          color: const Color(0xFF2979FF).withSafeOpacity(0.1), // 背景色
          borderRadius: BorderRadius.circular(12), // 圆角
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click, // 鼠标悬停显示点击光标
          child: Icon(icon, size: iconSize), // 选中图标
        ),
      ),
      label: label, // 标签
    );
  }
}

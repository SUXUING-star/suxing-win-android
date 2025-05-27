// lib/layouts/mobile/bottom_navigation_bar.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 检查是否是安卓横屏模式
    final bool isAndroidLandscape =
        DeviceUtils.isAndroid && DeviceUtils.isLandscape(context);

    // 根据模式调整内边距
    final verticalPadding = isAndroidLandscape ? 4.0 : 8.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: 8, vertical: verticalPadding),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              elevation: 0,
              backgroundColor: Colors.grey[50],
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Color(0xFF2979FF),
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isAndroidLandscape ? 10 : 12,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: isAndroidLandscape ? 10 : 12,
              ),
              items: [
                _buildNavItem(Icons.home_rounded, '首页', isAndroidLandscape),
                _buildNavItem(Icons.games_rounded, '游戏', isAndroidLandscape),
                _buildNavItem(Icons.forum_rounded, '帖子', isAndroidLandscape),
                _buildNavItem(Icons.rocket_launch, '动态', isAndroidLandscape),
                _buildNavItem(Icons.link_rounded, '外部', isAndroidLandscape),
                _buildNavItem(Icons.person_rounded, '我的', isAndroidLandscape),

                //_buildNavItem(Icons.rocket, 'ai', isAndroidLandscape),
              ],
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, bool isAndroidLandscape) {
    final padding = isAndroidLandscape ? 6.0 : 8.0;
    final iconSize = isAndroidLandscape ? 20.0 : 24.0;

    return BottomNavigationBarItem(
      icon: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Icon(icon, size: iconSize),
      ),
      activeIcon: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Color(0xFF2979FF).withSafeOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Icon(icon, size: iconSize),
        ),
      ),
      label: label,
    );
  }
}

// desktop_side_navigation.dart
import 'package:flutter/material.dart';
import '../../widgets/logo/app_logo.dart';

class DesktopSideNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const DesktopSideNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          // Logo区域
          Padding(
            padding: EdgeInsets.all(16),
            child: AppLogo(size: 48),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey[200]),
          // 导航项
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(context, 0, Icons.home_rounded, '首页'),
                _buildNavItem(context, 1, Icons.games_rounded, '游戏'),
                _buildNavItem(context, 2, Icons.link_rounded, '外部'),
                _buildNavItem(context, 3, Icons.forum_rounded, '论坛'),
                _buildNavItem(context, 4, Icons.person_rounded, '我的'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = currentIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF2979FF).withOpacity(0.1) : null,
              border: Border(
                left: BorderSide(
                  color: isSelected ? Color(0xFF2979FF) : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Color(0xFF2979FF) : Colors.grey[600],
                ),
                SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Color(0xFF2979FF) : Colors.grey[800],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
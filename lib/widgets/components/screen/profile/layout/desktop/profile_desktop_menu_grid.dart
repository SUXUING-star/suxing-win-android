// lib/widgets/components/screen/profile/layout/desktop/profile_desktop_menu_grid.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/profile/profile_constants.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/constants/profile/profile_menu_item.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class ProfileDesktopMenuGrid extends StatelessWidget {
  final double screenWidth;
  final List<ProfileMenuItem> menuItems;
  final WindowStateProvider windowStateProvider;

  const ProfileDesktopMenuGrid({
    super.key,
    required this.screenWidth,
    required this.menuItems,
    required this.windowStateProvider,
  });

  @override
  Widget build(BuildContext context) {
    // constraints.maxWidth 是 GridView 可用的最大宽度
    double maxCrossAxisExtent;
    // 可以根据屏幕宽度设定不同的期望子项宽度
    if (screenWidth < 800) {
      maxCrossAxisExtent = 160; // 小屏幕时，期望每个格子宽一点，列数少
    } else if (screenWidth < 1200) {
      maxCrossAxisExtent = 170; // 中等屏幕
    } else {
      maxCrossAxisExtent = 200; // 大屏幕时，期望每个格子宽一点
    }
    // 宽高比也可以动态计算，或者保持固定
    double childAspectRatio = 1.4; // 可以尝试固定或也根据 screenWidth 调整

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              '功能菜单',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            AppText(
              '管理您的账户和内容',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            Flexible(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxCrossAxisExtent, // 指定子项最大宽度
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  // 这里仍然可以根据 screenWidth 或 constraints.maxWidth / crossAxisCount (如果能拿到)
                  // 来调整 _buildMenuCard 内部的元素大小，但会更复杂
                  return _buildMenuCard(
                      context, item, screenWidth); // 暂时还用 screenWidth
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context, ProfileMenuItem item, double screenWidth) {
    final bool isSmallScreen = screenWidth < 800;
    final double iconSize = isSmallScreen ? 17 : 28;
    final double containerSize = isSmallScreen ? 36 : 60;
    final double fontSize = isSmallScreen ? 10 : 15;

    // 为每个菜单项定义独特的颜色方案

    final colorScheme =
        ProfileConstants.getProfileMenuColorScheme[item.title] ??
            {
              'background': Color(0xFFF0F0F0),
              'icon': Colors.grey.shade700,
            };

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            item.onTap ?? () => NavigationUtils.pushNamed(context, item.route),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme['background'],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  color: Colors.white.withSafeOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Icon(
                  item.icon,
                  color: colorScheme['icon'],
                  size: iconSize,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: AppText(
                  item.title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

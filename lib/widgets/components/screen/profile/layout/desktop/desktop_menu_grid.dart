// lib/widgets/components/screen/profile/desktop_menu_grid.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../../utils/font/font_config.dart';
import '../models/profile_menu_item.dart';

class DesktopMenuGrid extends StatelessWidget {
  final List<ProfileMenuItem> menuItems;

  const DesktopMenuGrid({
    Key? key,
    required this.menuItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth < 800 ? 2 : (screenWidth < 1200 ? 3 : 4);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '功能菜单',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '管理您的账户和内容',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
              ),
            ),
            SizedBox(height: 20),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // constraints.maxWidth 是 GridView 可用的最大宽度
                  double maxCrossAxisExtent;
                  // 可以根据屏幕宽度设定不同的期望子项宽度
                  if (screenWidth < 800) {
                    maxCrossAxisExtent = 180; // 小屏幕时，期望每个格子宽一点，列数少
                  } else if (screenWidth < 1200) {
                    maxCrossAxisExtent = 200; // 中等屏幕
                  } else {
                    maxCrossAxisExtent = 220; // 大屏幕时，期望每个格子宽一点
                  }
                  // 宽高比也可以动态计算，或者保持固定
                  double childAspectRatio = 1.4; // 可以尝试固定或也根据 screenWidth 调整

                  return GridView.builder(
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
                      return _buildMenuCard(context, item, screenWidth); // 暂时还用 screenWidth
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, ProfileMenuItem item, double screenWidth) {
    final bool isSmallScreen = screenWidth < 800;
    final double iconSize = isSmallScreen ? 17 : 28;
    final double containerSize = isSmallScreen ? 36 : 60;
    final double fontSize = isSmallScreen ? 10 : 15;

    // 为每个菜单项定义独特的颜色方案
    final Map<String, Map<String, Color>> menuColorScheme = {
      '管理员面板': {
        'background': Colors.white.withOpacity(0.9), // 淡紫色
        'icon': Color(0xFF6A5ACD), // 深紫色
      },
      '我的关注': {
        'background': Colors.white.withOpacity(0.9), // 淡蓝色
        'icon': Color(0xFF1E90FF), // 道奇蓝
      },
      '我的游戏': {
        'background': Colors.white.withOpacity(0.9), // 淡蓝色
        'icon': Colors.redAccent, // 红
      },

      '我的收藏': {
        'background': Colors.white.withOpacity(0.9),
        'icon': Color(0xFFFF69B4), // 热粉色
      },
      '签到': {
        'background': Colors.white.withOpacity(0.9),
        'icon': Color(0xFF3CB371), // 中海绿
      },
      '我的喜欢': {
        'background': Colors.white.withOpacity(0.9),
        'icon': Color(0xFFFF7F50), // 珊瑚色
      },
      '浏览历史': {
        'background': Colors.white.withOpacity(0.9),
        'icon': Color(0xFF4169E1), // 皇家蓝
      },
      '我的帖子': {
        'background': Colors.white.withOpacity(0.9),
        'icon': Color(0xFF8B4513), // 马鞍棕
      },
      '分享应用': {
        'background': Colors.white.withOpacity(0.9),
        'icon': Color(0xFF008B8B), // 深青色
      },
      '帮助与反馈': {
        'background': Colors.white.withOpacity(0.9),
        'icon': Color(0xFFDAA520), // 金杆色
      },
    };

    final colorScheme = menuColorScheme[item.title] ?? {
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
        onTap: item.onTap ?? () => NavigationUtils.pushNamed(context, item.route),
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
                  color: Colors.white.withOpacity(0.8),
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
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontFamily: FontConfig.defaultFontFamily,
                    fontFamilyFallback: FontConfig.fontFallback,
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
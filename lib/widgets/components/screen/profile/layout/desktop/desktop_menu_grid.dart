// lib/widgets/components/screen/profile/desktop_menu_grid.dart
import 'package:flutter/material.dart';
import '../../../../../../utils/font/font_config.dart';
import '../android/profile_menu_list.dart';

class DesktopMenuGrid extends StatelessWidget {
  final List<ProfileMenuItem> menuItems;

  const DesktopMenuGrid({
    Key? key,
    required this.menuItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 根据屏幕宽度调整布局
    final screenWidth = MediaQuery.of(context).size.width;
    // 根据屏幕宽度决定每行显示的项目数
    int crossAxisCount = screenWidth < 800 ? 2 : (screenWidth < 1200 ? 3 : 4);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '功能菜单',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '管理您的账户和内容',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
              ),
            ),
            SizedBox(height: 16), // 减少一些垂直间距

            // 使用 Flexible 替代 Expanded，更灵活地调整大小
            Flexible(
              fit: FlexFit.loose, // 允许小于其最大高度
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 动态计算 childAspectRatio
                  // 在较小的屏幕上，使项目高度增大以确保文本有足够空间显示
                  double childAspectRatio = screenWidth < 800 ? 1.3 : 1.5;

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 8, // 适度减小间距
                      mainAxisSpacing: 8, // 适度减小间距
                    ),
                    padding: EdgeInsets.zero,
                    // 使用 shrinkWrap 防止 GridView 尝试占用尽可能多的空间
                    // shrinkWrap: true, // 移除 shrinkWrap
                    // 禁用滚动以避免嵌套滚动冲突
                    // physics: NeverScrollableScrollPhysics(), // 移除此行以启用滚动
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      return _buildMenuCard(context, item, screenWidth);
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
    // 根据屏幕宽度调整卡片内的尺寸
    final bool isSmallScreen = screenWidth < 800;
    final double iconSize = isSmallScreen ? 18 : 22;
    final double containerSize = isSmallScreen ? 36 : 40;
    final double fontSize = isSmallScreen ? 12 : 14;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: item.onTap ?? () => Navigator.pushNamed(context, item.route),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), // 减小内边距
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  color: Theme.of(context).primaryColor,
                  size: iconSize,
                ),
              ),
              SizedBox(height: 4), // 减小间距
              Flexible(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    fontFamily: FontConfig.defaultFontFamily,
                    fontFamilyFallback: FontConfig.fontFallback,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // 限制最大行数
                  overflow: TextOverflow.ellipsis, // 文本溢出时显示省略号
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
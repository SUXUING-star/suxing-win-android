// lib/widgets/components/screen/profile/desktop_menu_grid.dart
import 'package:flutter/material.dart';
import '../../../../utils/font/font_config.dart';
import 'profile_menu_list.dart';

class DesktopMenuGrid extends StatelessWidget {
  final List<ProfileMenuItem> menuItems;

  const DesktopMenuGrid({
    Key? key,
    required this.menuItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 每行显示4个而不是3个
                  childAspectRatio: 1.5, // 更宽扁的比例
                  crossAxisSpacing: 10, // 减小间距
                  mainAxisSpacing: 10, // 减小间距
                ),
                padding: EdgeInsets.zero, // 移除内边距
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return _buildMenuCard(context, item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, ProfileMenuItem item) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero, // 移除外边距
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: item.onTap ?? () => Navigator.pushNamed(context, item.route),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4), // 减小内边距
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // 使列占用最少的空间
            children: [
              Container(
                width: 40, // 减小图标容器大小
                height: 40, // 减小图标容器大小
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  color: Theme.of(context).primaryColor,
                  size: 22, // 减小图标大小
                ),
              ),
              SizedBox(height: 6), // 减小间距
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 14, // 减小字体大小
                  fontWeight: FontWeight.w500,
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
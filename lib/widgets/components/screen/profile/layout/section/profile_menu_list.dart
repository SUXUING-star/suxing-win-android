// lib/widgets/components/screen/profile/profile_menu_list.dart
import 'package:flutter/material.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../../../../utils/font/font_config.dart';

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final String route;
  final VoidCallback? onTap;

  ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.route,
    this.onTap,
  });
}

class ProfileMenuList extends StatelessWidget {
  final List<ProfileMenuItem> menuItems;
  final VoidCallback onLogout;

  const ProfileMenuList({
    Key? key,
    required this.menuItems,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...menuItems.map((item) => ListTile(
          leading: Icon(item.icon),
          title: Text(
            item.title,
            style: TextStyle(
              fontFamily: FontConfig.defaultFontFamily,
              fontFamilyFallback: FontConfig.fontFallback,
            ),
          ),
          trailing: Icon(Icons.chevron_right),
          onTap: item.onTap ?? () => Navigator.pushNamed(context, item.route),
        )).toList(),
        ListTile(
          leading: Icon(Icons.exit_to_app, color: Colors.red),
          title: Text(
            '退出登录',
            style: TextStyle(
              color: Colors.red,
              fontFamily: FontConfig.defaultFontFamily,
              fontFamilyFallback: FontConfig.fontFallback,
            ),
          ),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '退出登录',
          style: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontFamilyFallback: FontConfig.fontFallback,
          ),
        ),
        content: Text(
          '确定要退出登录吗？',
          style: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontFamilyFallback: FontConfig.fontFallback,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLogout();
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
            child: Text(
              '确定',
              style: TextStyle(
                fontFamily: FontConfig.defaultFontFamily,
                fontFamilyFallback: FontConfig.fontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
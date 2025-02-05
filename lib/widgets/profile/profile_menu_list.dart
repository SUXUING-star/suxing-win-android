// lib/widgets/profile/profile_menu_list.dart
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

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
          title: Text(item.title),
          trailing: Icon(Icons.chevron_right),
          onTap: item.onTap ?? () => Navigator.pushNamed(context, item.route),
        )).toList(),
        ListTile(
          leading: Icon(Icons.exit_to_app),
          title: Text('退出登录'),
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
        title: Text('退出登录'),
        content: Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLogout();
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }
}
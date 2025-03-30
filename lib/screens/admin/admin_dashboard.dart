// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth/auth_provider.dart';
import 'widgets/game_management.dart';
import 'widgets/tool_management.dart';
import 'widgets/link_management.dart';
import 'widgets/user_management.dart';
import 'widgets/ip_management.dart';
import 'widgets/maintenance_management.dart';
import 'widgets/announcement_management.dart'; // 导入公告管理组件
import '../../widgets/ui/appbar/custom_app_bar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  // 添加公告管理页面到页面列表
  List<Widget> _getPages(bool isSuperAdmin) {
    final commonPages = [
      const GameManagement(),
      const ToolManagement(),
      const LinkManagement(),

    ];

    // 只有超级管理员可以看到用户管理和IP管理
    if (isSuperAdmin) {
      return [
        ...commonPages,
        const UserManagement(),
        const AnnouncementManagement(), // 添加公告管理页面
        const MaintenanceManagement(),

        const IPManagement(),
      ];
    }

    return commonPages;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('无权限访问管理界面'),
        ),
      );
    }

    final isSuperAdmin = authProvider.isSuperAdmin;
    final pages = _getPages(isSuperAdmin);

    return Scaffold(
      appBar: CustomAppBar(
        title: _getTitle(isSuperAdmin),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _buildDestinations(isSuperAdmin),
      ),
    );
  }

  String _getTitle(bool isSuperAdmin) {
    if (!isSuperAdmin && _selectedIndex >= 5) {
      return '管理面板';
    }

    switch (_selectedIndex) {
      case 0:
        return '游戏管理';
      case 1:
        return '工具管理';
      case 2:
        return '链接管理';
      case 3:
        return '用户管理';

      case 4:
        return '公告管理'; // 添加公告管理标题
      case 5:
        return '系统维护';

      case 6:
        return 'IP管理';
      default:
        return '管理面板';
    }
  }

  List<NavigationDestination> _buildDestinations(bool isSuperAdmin) {
    final commonDestinations = [
      const NavigationDestination(
        icon: Icon(Icons.games),
        label: '游戏管理',
      ),
      const NavigationDestination(
        icon: Icon(Icons.build),
        label: '工具管理',
      ),
      const NavigationDestination(
        icon: Icon(Icons.link),
        label: '链接管理',
      ),

    ];

    // 只有超级管理员可以看到用户管理和IP管理
    if (isSuperAdmin) {
      return [
        ...commonDestinations,
        const NavigationDestination(
          icon: Icon(Icons.person),
          label: '用户管理',
        ),
        const NavigationDestination(
          icon: Icon(Icons.announcement), // 添加公告管理图标
          label: '公告管理', // 添加公告管理标签
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings_applications),
          label: '系统维护',
        ),
        const NavigationDestination(
          icon: Icon(Icons.security),
          label: 'IP管理',
        ),
      ];
    }

    return commonDestinations;
  }
}
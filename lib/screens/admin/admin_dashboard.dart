// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth/auth_provider.dart';
import 'widgets/game_management.dart';
import 'widgets/tool_management.dart';
import 'widgets/link_management.dart';
import 'widgets/user_management.dart';
import '../../widgets/common/custom_app_bar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const GameManagement(),
    const ToolManagement(),
    const LinkManagement(),
    const UserManagement(),
  ];

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

    return Scaffold(
      appBar: CustomAppBar(
        title: _getTitle(),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.games),
            label: '游戏管理',
          ),
          NavigationDestination(
            icon: Icon(Icons.build),
            label: '工具管理',
          ),
          NavigationDestination(
            icon: Icon(Icons.link),
            label: '链接管理',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: '用户管理',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return '游戏管理';
      case 1:
        return '工具管理';
      case 2:
        return '链接管理';
      case 3:
        return '用户管理';
      default:
        return '管理面板';
    }
  }
}
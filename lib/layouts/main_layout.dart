// lib/layouts/main_layout.dart
import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/game/games_list_screen.dart';
import '../screens/linkstools/linkstools_screen.dart';
import '../screens/forum/forum_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth/auth_provider.dart';
import '../services/update/update_service.dart';
import '../services/ban/user_ban_service.dart';
import '../services/user_service.dart';
import 'android/top_navigation_bar.dart';
import 'android/bottom_navigation_bar.dart';
import '../widgets/dialogs/force_update_dialog.dart';
import '../widgets/dialogs/user_ban_dialog.dart';

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final UserService _userService = UserService();
  final UserBanService _banService = UserBanService();
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(),
      GamesListScreen(),
      LinksToolsScreen(),
      ForumScreen(),
      ProfileScreen(),
    ];
    // 应用启动时检查更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
      _checkBanStatus();
    });
  }
  Future<void> _checkBanStatus() async {
    try {
      final userId = await _userService.currentUserId;
      if (userId != null) {
        final ban = await _banService.checkUserBan(userId);
        if (ban != null && mounted) {
          // 显示封禁对话框
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => UserBanDialog(ban: ban),
          );
        }
      }
    } catch (e) {
      print('Check ban status error: $e');
    }
  }


  Future<void> _checkForUpdates() async {
    if (!mounted) return;

    final updateService = Provider.of<UpdateService>(context, listen: false);
    await updateService.checkForUpdates();

    // 如果有强制更新并且界面还在挂载状态，显示对话框
    if (mounted && updateService.updateAvailable && updateService.forceUpdate) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ForceUpdateDialog(
          currentVersion: updateService.latestVersion ?? '',
          latestVersion: updateService.latestVersion ?? '',
          updateMessage: updateService.updateMessage,
          changelog: updateService.changelog,
          updateUrl: updateService.updateUrl ?? '',
        ),
      );
    }
  }

  void _handleProfileTap() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      setState(() => _currentIndex = 4);
    } else {
      Navigator.pushNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigationBar(

        onLogoTap: () {
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
          }
        },
        onProfileTap: _handleProfileTap,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
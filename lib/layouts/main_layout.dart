// lib/layouts/main_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/screens/ai/gemini_chat_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/game/list/games_list_screen.dart';
import '../screens/linkstools/linkstools_screen.dart';
import '../screens/activity/activity_feed_screen.dart';
import '../screens/forum/forum_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth/auth_provider.dart';
import '../services/main/update/update_service.dart';
import '../services/main/user/user_ban_service.dart';
import '../services/main/user/user_service.dart';
import '../services/main/announcement/announcement_service.dart';
import '../services/main/network/network_manager.dart';  // 导入网络管理器
import 'android/top_navigation_bar.dart';
import 'android/bottom_navigation_bar.dart';
import '../widgets/components/dialogs/update/force_update_dialog.dart';
import '../widgets/components/dialogs/ban/user_ban_dialog.dart';
import '../widgets/components/dialogs/announcement/announcement_dialog.dart';
import '../widgets/components/screen/home/player/floating_music_player.dart';


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
      ActivityFeedScreen(),
      ProfileScreen(),

      //GeminiChatScreen(),
    ];
    // 应用启动时检查更新、公告和封禁状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
      _checkBanStatus();
      _checkAnnouncements(); // 新增：检查公告

      // 确保网络管理器已经初始化
      _ensureNetworkManagerInitialized();
    });
  }

  // 确保网络管理器已初始化
  Future<void> _ensureNetworkManagerInitialized() async {
    try {
      // 网络管理器应该已在app_initializer中初始化
      // 这里主要是确保它处于活动状态
      final networkManager = Provider.of<NetworkManager>(context, listen: false);

      if (!networkManager.isInitialized) {
        await networkManager.init();
      }
    } catch (e) {
      print('确保网络管理器初始化时出错: $e');
    }
  }

  // 新增：检查公告方法
  Future<void> _checkAnnouncements() async {
    try {
      if (!mounted) return;

      final announcementService = Provider.of<AnnouncementService>(context, listen: false);

      // 确保服务已初始化
      if (!announcementService.isInitialized) {
        await announcementService.init();
      }

      // 获取公告
      await announcementService.getActiveAnnouncements();

      // 显示未读公告 (如果有)
      final unreadAnnouncements = announcementService.getUnreadAnnouncements();
      if (unreadAnnouncements.isNotEmpty && mounted) {
        // 导入 announcement_dialog.dart 中的 showAnnouncementDialog 函数
        showAnnouncementDialog(
          context,
          unreadAnnouncements.first,
        );
      }
    } catch (e) {
      print('Check announcements error: $e');
    }
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

  // 网络重连成功后的回调
  void _handleNetworkReconnected() {
    // 刷新公告和封禁状态
    _checkAnnouncements();
    _checkBanStatus();

    // 可以在这里添加其他需要在网络重连后刷新的内容
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络连接已恢复，数据已刷新'))
    );
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
      body: Stack(
        children: [
          _screens[_currentIndex],
          //FloatingMusicPlayer(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
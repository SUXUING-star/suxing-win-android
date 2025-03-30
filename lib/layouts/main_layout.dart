// lib/layouts/main_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
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
import '../services/main/network/network_manager.dart';
import '../utils/device/device_utils.dart';
import 'mobile/top_navigation_bar.dart';
import 'mobile/bottom_navigation_bar.dart';
import '../widgets/components/dialogs/update/force_update_dialog.dart';
import '../widgets/components/dialogs/ban/user_ban_dialog.dart';
import '../widgets/components/dialogs/announcement/announcement_dialog.dart';

class MainLayout extends StatefulWidget {
  // 移除固定的静态键，改为可选参数
  static final GlobalKey<_MainLayoutState> _privateMainLayoutKey = GlobalKey<_MainLayoutState>();

  // 添加静态方法获取主布局状态，避免直接暴露键
  static _MainLayoutState? get currentState => _privateMainLayoutKey.currentState;

  static void navigateTo(int index) {
    final state = currentState;
    if (state != null) {
      state._handleNavigation(index);
    } else {
      // If state is not available yet, store the index for later
      _pendingNavigationIndex = index;
    }
  }

  // 添加一个公开的方法来设置待处理的导航索引
  static void setPendingNavigation(int index) {
    _pendingNavigationIndex = index;
  }

  static int? _pendingNavigationIndex;

  // 修改构造函数，使用私有静态键
  MainLayout() : super(key: _privateMainLayoutKey);

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
      ForumScreen(),
      ActivityFeedScreen(),
      LinksToolsScreen(),
      ProfileScreen(),
    ];

    // 检查是否有待处理的导航请求
    if (MainLayout._pendingNavigationIndex != null) {
      _currentIndex = MainLayout._pendingNavigationIndex!;
      MainLayout._pendingNavigationIndex = null;
    }


    // 应用启动时检查更新、公告和封禁状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
      _checkBanStatus();
      _checkAnnouncements();
      _ensureNetworkManagerInitialized();
    });
  }

  // 确保网络管理器已初始化
  Future<void> _ensureNetworkManagerInitialized() async {
    try {
      final networkManager = Provider.of<NetworkManager>(context, listen: false);
      if (!networkManager.isInitialized) {
        await networkManager.init();
      }
    } catch (e) {
      print('确保网络管理器初始化时出错: $e');
    }
  }

  // 检查公告方法
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
      setState(() => _currentIndex = 5);
    } else {
      NavigationUtils.pushNamed(context, '/login');
    }
  }

  // 处理导航，供静态方法调用
  void _handleNavigation(int index) {
    if (_currentIndex != index && index < _screens.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop;

    return Scaffold(
      // 移动平台显示顶部导航栏，桌面平台不显示
      appBar: !isDesktop ? TopNavigationBar(
        onLogoTap: () {
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
          }
        },
        onProfileTap: _handleProfileTap,
      ) : null,
      body: Stack(
        children: [
          _screens[_currentIndex],
        ],
      ),
      // 移动平台显示底部导航栏，桌面平台不显示
      bottomNavigationBar: !isDesktop ? CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _handleNavigation,
      ) : null,
    );
  }
}
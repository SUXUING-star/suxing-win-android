// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/announcement/announcement_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/services/main/linktool/link_tool_service.dart';
import 'package:suxingchahui/services/main/maintenance/maintenance_service.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/screens/admin/widgets/game_management.dart';
import 'package:suxingchahui/screens/admin/widgets/tool_management.dart';
import 'package:suxingchahui/screens/admin/widgets/link_management.dart';
import 'package:suxingchahui/screens/admin/widgets/user_management.dart';
import 'package:suxingchahui/screens/admin/widgets/ip_management.dart';
import 'package:suxingchahui/screens/admin/widgets/maintenance_management.dart';
import 'package:suxingchahui/screens/admin/widgets/announcement_management.dart'; // 导入公告管理组件
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';

class AdminDashboard extends StatefulWidget {
  final AuthProvider authProvider;
  final GameService gameService;
  final LinkToolService linkToolService;
  final UserService userService;
  final InputStateService inputStateService;
  final MaintenanceService maintenanceService;
  final AnnouncementService announcementService;
  const AdminDashboard({
    super.key,
    required this.authProvider,
    required this.gameService,
    required this.userService,
    required this.inputStateService,
    required this.linkToolService,
    required this.maintenanceService,
    required this.announcementService,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  String? _currentUserId;
  bool _hasInitializedPage = false;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _currentUserId = widget.authProvider.currentUserId;
    super.didChangeDependencies();
    if (!_hasInitializedPage) {
      _pages = _getPages();
      _hasInitializedPage = true;
    }
  }

  @override
  void didUpdateWidget(covariant AdminDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentUserId != widget.authProvider.currentUserId ||
        oldWidget.authProvider.currentUserId !=
            widget.authProvider.currentUserId) {
      setState(() {
        _currentUserId = widget.authProvider.currentUserId;
      });
    }
  }

  // 添加公告管理页面到页面列表
  List<Widget> _getPages() {
    final bool isSuperAdmin = widget.authProvider.isSuperAdmin;
    final User? currentUser = widget.authProvider.currentUser;
    final commonPages = [
      GameManagement(
        currentUser: currentUser,
        gameService: widget.gameService,
        inputStateService: widget.inputStateService,
      ),
      ToolManagement(
        linkToolService: widget.linkToolService,
        inputStateService: widget.inputStateService,
      ),
      LinkManagement(
        linkToolService: widget.linkToolService,
        inputStateService: widget.inputStateService,
      ),
    ];

    // 只有超级管理员可以看到用户管理和IP管理
    if (isSuperAdmin) {
      return [
        ...commonPages,
        UserManagement(
          currentUser: currentUser,
          inputStateService: widget.inputStateService,
          userService: widget.userService,
        ),
        AnnouncementManagement(
          announcementService: widget.announcementService,
        ), // 添加公告管理页面
        MaintenanceManagement(
          maintenanceService: widget.maintenanceService,
          inputStateService: widget.inputStateService,
        ),
        IPManagement(
          inputStateService: widget.inputStateService,
        ),
      ];
    }

    return commonPages;
  }

  List<NavigationDestination> _buildDestinations() {
    final bool isSuperAdmin = widget.authProvider.isSuperAdmin;
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

  String _getTitle() {
    final bool isSuperAdmin = widget.authProvider.isSuperAdmin;
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream,
      initialData: widget.authProvider.currentUser,
      builder: (context, currentUserSnapshot) {
        final User? currentUser = currentUserSnapshot.data;

        final isAdmin = currentUser?.isAdmin ?? false;

        if (isAdmin) {
          return CustomErrorWidget(
            title: "权限错误",
            errorMessage: "你不是管理员无法查看此页面",
            onRetry: () => NavigationUtils.pop(context),
            retryText: "返回上一个页面",
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
            destinations: _buildDestinations(),
          ),
        );
      },
    );
  }
}

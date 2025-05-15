// lib/screens/profile/profile_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_lr_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/screen/profile/layout/models/profile_menu_item.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/components/screen/profile/layout/mobile/mobile_profile_header.dart';
import 'package:suxingchahui/widgets/components/screen/profile/layout/mobile/mobile_profile_menu_list.dart';
import 'package:suxingchahui/widgets/components/screen/profile/layout/desktop/desktop_profile_card.dart';
import 'package:suxingchahui/widgets/components/screen/profile/layout/desktop/desktop_menu_grid.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/edit_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SnackBarNotifierMixin {
  String? _error;
  bool _isInitialized = false;
  bool _isVisible = false;
  bool _isRefreshing = false;
  final visibilityKey = const Key('profile_screen_visibility_detector');
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(minutes: 1);
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _triggerInitialLoad() {
    if (!_isInitialized && _isVisible) {
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          // 可选：调用 Provider 确保数据加载
          // Provider.of<AuthProvider>(context, listen: false).ensureUserLoaded();
        }
      });
    }
  }

  Future<void> _refreshProfile() async {
    if (_isRefreshing) return;

    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minRefreshInterval) {
      final remaining = _minRefreshInterval - now.difference(_lastRefreshTime!);
      final remainingSeconds = remaining.inSeconds + 1;
      if (mounted) {
        AppSnackBar.showInfo(context, '刷新太频繁，请 $remainingSeconds 秒后再试');
      }
      return;
    }

    if (!mounted) return;
    if (!_authProvider.isLoggedIn) {
      if (mounted) {
        setState(() {
          _error = null;
          _isInitialized = true;
        });
      }
      return;
    }

    setState(() {
      _isRefreshing = true;
      _error = null;
    });

    try {
      await _authProvider.refreshUserState();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '刷新失败: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _lastRefreshTime = DateTime.now();
        });
      }
    }
  }

  void _showEditProfileDialog(User currentUser, BuildContext context) {
    EditDialog.show(
      context: context,
      title: '修改用户名',
      initialText: currentUser.username,
      hintText: '请输入新的用户名',
      maxLines: 1,
      iconData: Icons.person_outline,
      onSave: (newUsername) async {
        if (newUsername.trim().isEmpty) {
          AppSnackBar.showWarning(context, '用户名不能为空');
          return;
        }
        if (newUsername.trim() == currentUser.username) return;

        try {
          final userService = context.read<UserService>();
          await userService.updateUserProfile(username: newUsername.trim());
          await _authProvider.refreshUserState();
          showSnackbar(message: '用户名更新成功', type: SnackbarType.success);
        } catch (e) {
          showSnackbar(message: '更新失败：$e', type: SnackbarType.error);
        }
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    CustomConfirmDialog.show(
      context: context,
      title: '退出登录',
      message: '您确定要退出当前账号吗？',
      confirmButtonText: '确认退出',
      cancelButtonText: '取消',
      confirmButtonColor: Colors.red,
      iconData: Icons.logout,
      iconColor: Colors.orange,
      onConfirm: () async {
        try {
          await authProvider.signOut();
          if (mounted) {
            setState(() {
              _error = null;
              _isInitialized = false;
              _isRefreshing = false;
              _lastRefreshTime = null;
            });
            NavigationUtils.navigateToHome(this.context, tabIndex: 0);
          }
        } catch (e) {
          showSnackbar(message: '退出登录失败: $e', type: SnackbarType.error);
        }
      },
    );
  }

  List<ProfileMenuItem> _getMenuItems(
      AuthProvider authProvider, User? currentUser) {
    return [
      if (authProvider.isAdmin)
        ProfileMenuItem(
            icon: Icons.admin_panel_settings,
            title: '管理员面板',
            route: AppRoutes.adminDashboard),
      ProfileMenuItem(
        icon: Icons.people_outline,
        title: '我的关注',
        route: '',
        onTap: () {
          if (currentUser != null) {
            NavigationUtils.pushNamed(context, AppRoutes.userFollows,
                arguments: {
                  'userId': currentUser.id,
                  'username': currentUser.username,
                  'initialShowFollowing': true
                });
          }
        },
      ),
      ProfileMenuItem(
          icon: Icons.games_outlined, title: '我的游戏', route: AppRoutes.myGames),
      ProfileMenuItem(
          icon: Icons.forum_outlined, title: '我的帖子', route: AppRoutes.myPosts),
      ProfileMenuItem(
          icon: Icons.collections_bookmark_outlined,
          title: '我的收藏',
          route: AppRoutes.myCollections),
      ProfileMenuItem(
          icon: Icons.favorite_border,
          title: '我的喜欢',
          route: AppRoutes.favorites),
      ProfileMenuItem(
        icon: Icons.rocket_launch_outlined,
        title: '我的动态',
        route: '',
        onTap: () {
          if (currentUser != null) {
            NavigationUtils.pushNamed(
              context,
              AppRoutes.userActivities,
              arguments: currentUser.id,
            );
          } else {
            if (mounted) AppSnackBar.showError(context, '无法加载用户数据');
          }
        },
      ),
      ProfileMenuItem(
          icon: Icons.calendar_today_outlined,
          title: '签到',
          route: AppRoutes.checkin),
      ProfileMenuItem(
          icon: Icons.history, title: '浏览历史', route: AppRoutes.history),
      ProfileMenuItem(
          icon: Icons.share_outlined,
          title: '分享应用',
          route: '',
          onTap: () {
            if (mounted) AppSnackBar.showInfo(context, '分享功能开发中');
          }),
      ProfileMenuItem(
          icon: Icons.info_outline, title: '支持我们', route: AppRoutes.about),
      ProfileMenuItem(
          icon: Icons.settings, title: '设置', route: AppRoutes.settingPage),
    ];
  }

  void _handleUploadStateChanged(bool isLoading) {
    if (mounted && _isRefreshing != isLoading) {
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _isRefreshing = isLoading;
          });
        }
      });
    }
  }

  Future<void> _handleUploadSuccess(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!mounted) return;
    try {
      await authProvider.refreshUserState();
      showSnackbar(message: '用户信息已刷新', type: SnackbarType.success);
    } catch (e) {
      showSnackbar(message: '刷新用户信息失败: $e', type: SnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool useDesktopLayout = isDesktop && screenSize.width > 900;

    buildSnackBar(context);

    return VisibilityDetector(
      key: visibilityKey,
      onVisibilityChanged: (VisibilityInfo info) {
        final bool currentlyVisible = info.visibleFraction > 0;
        if (currentlyVisible != _isVisible) {
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _isVisible = currentlyVisible;
              });
              if (_isVisible) {
                _triggerInitialLoad();
              }
            } else {
              _isVisible = currentlyVisible;
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(title: '个人中心', actions: const []),
        body: RefreshIndicator(
          onRefresh: () => _refreshProfile(),
          child: _buildProfileContent(context, useDesktopLayout),
        ),
        floatingActionButton: _buildFloatButtons(context),
      ),
    );
  }

  Widget _buildFloatButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
      child: FloatingActionButtonGroup(
        spacing: 16.0,
        alignment: MainAxisAlignment.end,
        children: [
          GenericFloatingActionButton(
            icon: Icons.settings_outlined,
            onPressed: () =>
                NavigationUtils.pushNamed(context, AppRoutes.settingPage),
            heroTag: "profile_setting_fab",
            tooltip: "设置",
          )
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, bool useDesktopLayout) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn) {
          if (_isInitialized || _error != null || _isRefreshing) {
            Future.microtask(() {
              if (mounted) {
                setState(() {
                  _error = null;
                  _isInitialized = false;
                  _isRefreshing = false;
                  _lastRefreshTime = null;
                });
              }
            });
          }
          return FadeInSlideUpItem(
              duration: const Duration(milliseconds: 300),
              child: LoginPromptWidget(isDesktop: useDesktopLayout));
        }

        final User? currentUser = authProvider.currentUser;

        if (_isRefreshing && currentUser == null && _error == null) {
          return LoadingWidget.fullScreen(message: "正在刷新...");
        } else if (!_isInitialized && currentUser == null && _error == null) {
          // 等待初始化或Provider加载数据
          return LoadingWidget.inline();
        } else if (_error != null) {
          return Center(
              child: InlineErrorWidget(
                  errorMessage: _error!, onRetry: () => _refreshProfile()));
        } else if (currentUser == null) {
          return Center(
              child: CustomErrorWidget(
                  errorMessage: "无法获取用户信息，请尝试刷新。",
                  onRetry: () => _refreshProfile()));
        }

        // --- 显示用户信息 ---
        final menuItems = _getMenuItems(authProvider, currentUser);

        return Stack(
          children: [
            // 实际内容
            if (useDesktopLayout)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: FadeInSlideLRItem(
                        slideDirection: SlideDirection.left,
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 100),
                        child: DesktopProfileCard(
                          user: currentUser,
                          onEditProfile: () =>
                              _showEditProfileDialog(currentUser, context),
                          onLogout: () => _showLogoutDialog(context),
                          onUploadStateChanged: _handleUploadStateChanged,
                          onUploadSuccess: () => _handleUploadSuccess(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: FadeInSlideLRItem(
                        slideDirection: SlideDirection.right,
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 250),
                        child: DesktopMenuGrid(menuItems: menuItems),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView(
                // 确保移动端可滚动以触发 RefreshIndicator
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  FadeInSlideUpItem(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 100),
                    child: MobileProfileHeader(
                      user: currentUser,
                      onEditProfile: () =>
                          _showEditProfileDialog(currentUser, context),
                      onLogout: () => _showLogoutDialog(context),
                      onUploadStateChanged: _handleUploadStateChanged,
                      onUploadSuccess: () => _handleUploadSuccess(context),
                    ),
                  ),
                  FadeInSlideUpItem(
                    duration: const Duration(milliseconds: 450),
                    delay: const Duration(milliseconds: 200),
                    child: MobileProfileMenuList(menuItems: menuItems),
                  ),
                  const SizedBox(height: 80), // 底部留白
                ],
              ),

            // 刷新时的加载指示器 (覆盖在内容之上)
            if (_isRefreshing) // 只有在有内容显示时才覆盖指示器
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.1), // 半透明遮罩
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
          ],
        );
      },
    );
  }
}

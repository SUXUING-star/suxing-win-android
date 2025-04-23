// lib/screens/profile/profile_screen.dart
import 'dart:async'; // 引入 Completer (如果需要 Lock, 虽然这里没直接用)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_lr_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:visibility_detector/visibility_detector.dart'; // <--- 引入 VisibilityDetector
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/screen/profile/layout/models/profile_menu_item.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user/user.dart';
import '../../providers/auth/auth_provider.dart'; // <--- 引入 AuthProvider
import '../../routes/app_routes.dart';
import '../../services/main/user/user_service.dart';
import '../../utils/device/device_utils.dart';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/profile/layout/mobile/mobile_profile_header.dart';
import '../../widgets/components/screen/profile/layout/mobile/mobile_profile_menu_list.dart';
import '../../widgets/components/screen/profile/layout/desktop/desktop_profile_card.dart';
import '../../widgets/components/screen/profile/layout/desktop/desktop_menu_grid.dart';
import '../../widgets/ui/common/error_widget.dart';
import '../../widgets/ui/common/login_prompt_widget.dart';
import '../../widgets/ui/common/loading_widget.dart';
import '../../widgets/ui/dialogs/edit_dialog.dart';
import '../../widgets/ui/dialogs/confirm_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

// *** 添加 TickerProviderStateMixin 用于动画 ***
// 如果你的 FadeIn* 组件内部需要 Ticker，可能需要这个
// class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  // --- 数据状态 ---
  User? _user;
  String? _error;

  // --- 懒加载与状态管理 ---
  bool _isInitialized = false; // 是否已尝试进行首次加载（成功或失败）
  bool _isVisible = false;     // 当前 Widget 是否可见
  bool _isLoadingData = false; // 是否正在加载数据 (首次或刷新)
  bool _hasAttemptedInitialLoad = false; // 标记是否已尝试过 triggerInitialLoad

  // Key for VisibilityDetector
  final visibilityKey = const Key('profile_screen_visibility_detector');

  @override
  void initState() {
    super.initState();
    // 不在 initState 中加载数据
    print("ProfileScreen: initState");
  }

  @override
  void dispose() {
    print("ProfileScreen: dispose");
    // 理论上 VisibilityDetector 会处理自己的监听器，但如果需要清理其他资源在这里做
    super.dispose();
  }

  // --- 核心：触发首次数据加载 ---
  void _triggerInitialLoad(BuildContext context) {
    // 防止重复触发同一个“首次”加载
    if (_hasAttemptedInitialLoad || !_isVisible) {
      // print("ProfileScreen: Skipping initial load trigger. Attempted: $_hasAttemptedInitialLoad, Visible: $_isVisible");
      return;
    }

    // 标记已尝试首次加载
    _hasAttemptedInitialLoad = true;
    print("ProfileScreen: Attempting initial load trigger.");

    // 使用 listen: false 因为这是在回调中，不需要监听变化，只获取当前状态
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 检查是否登录，只有登录了才加载用户信息
    if (authProvider.isLoggedIn) {
      print("ProfileScreen: User is logged in, calling _loadUserProfile.");
      // 标记为已初始化（开始加载过程）
      // 确保在 build 循环外更新状态
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _isInitialized = true; // 标记初始化流程已启动
          });
        }
        _loadUserProfile(context); // 调用实际加载方法
      });
    } else {
      print("ProfileScreen: User not logged in during initial load trigger.");
      // 如果未登录，也算“初始化”完成（显示登录提示），但没有加载数据
      Future.microtask(() {
        if (mounted && !_isInitialized) { // 只有在未初始化时才标记
          setState(() => _isInitialized = true);
        }
      });
    }
  }


  // --- 加载用户配置文件的核心方法 ---
  Future<void> _loadUserProfile(BuildContext context) async {
    // 防止重复加载
    if (_isLoadingData) {
      print("ProfileScreen: Load already in progress, skipping.");
      return;
    }
    if (!mounted) {
      print("ProfileScreen: Load cancelled, widget not mounted.");
      return;
    }

    print("ProfileScreen: Starting to load user profile...");
    setState(() {
      _isLoadingData = true; // 开始加载
      _error = null; // 清除旧错误
    });

    // 获取 AuthProvider (listen: false, 因为是在操作内部)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // 直接从 AuthProvider 获取当前用户
      // AuthProvider 内部应该处理好用户数据的获取和缓存
      final user = authProvider.currentUser;

      // 再次检查 mounted，因为 await 可能耗时
      if (!mounted) {
        print("ProfileScreen: Load cancelled after getting user, widget not mounted.");
        _isLoadingData = false; // 重置加载状态
        return;
      }

      if (user != null) {
        print("ProfileScreen: User data loaded successfully: ${user.username}");
        setState(() {
          _user = user;
          _isLoadingData = false;
          _isInitialized = true; // 确认初始化完成
        });
      } else {
        // 虽然 authProvider.isLoggedIn 可能为 true, 但 currentUser 可能是 null
        // (例如，AuthProvider 正在刷新但暂时失败，或者初始化逻辑问题)
        print("ProfileScreen: User is null despite being logged in (potentially).");
        setState(() {
          _error = '无法获取用户信息，请稍后重试。';
          _isLoadingData = false;
          _isInitialized = true; // 即使失败，也标记初始化尝试完成
          _user = null;
        });
      }

    } catch (e, stackTrace) {
      print("ProfileScreen: Error loading user profile: $e\n$stackTrace");
      if (!mounted) return;
      setState(() {
        _error = '加载个人信息失败: $e';
        _isLoadingData = false;
        _isInitialized = true; // 标记初始化尝试完成
        _user = null;
      });
    }
  }

  // --- 刷新用户配置文件 ---
  Future<void> _refreshProfile(BuildContext context) async {
    if (_isLoadingData) {
      print("ProfileScreen: Refresh skipped, already loading.");
      return;
    }
    if (!mounted) return;

    print("ProfileScreen: Refresh triggered.");
    // (可选) 清除相关缓存
    try {
      // 注意：如果 AuthProvider 负责管理用户数据，理想情况下刷新操作
      // 应该调用 AuthProvider 的刷新方法，而不是直接调用 UserService。
      // 这里我们假设 AuthProvider 的 refreshUserState 会更新 currentUser。
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        setState(() {
          _isLoadingData = true; // 显示加载指示器
          _error = null;
        });
        await authProvider.refreshUserState(); // 让 Provider 处理刷新逻辑
        // AuthProvider 刷新后会 notifyListeners, build 方法会使用新的 currentUser
        // 但是为了确保 _loadUserProfile 的状态更新，我们可以在这里再次调用或依赖 build
        // 简单起见，我们假设 AuthProvider 更新后，这里的 build 会拿到新数据
        // 但为了明确更新 _user 和 _isLoadingData，可以再次调用 _loadUserProfile (虽然有点冗余)
        // 或者直接在 build 中处理 authProvider.isRefreshing 状态？
        // 采取更直接的方式：在 refreshUserState 后重新调用 _loadUserProfile
        // 但要注意这可能会导致重复的 notifyListeners。
        // 更好的方式是依赖 build 方法的 watch 来获取最新 user。
        // 这里暂时保持调用 _loadUserProfile 以更新本地状态。
        await _loadUserProfile(context); // 用最新的 provider 数据更新本地 state
      } else {
        print("ProfileScreen: Refresh skipped, user not logged in.");
        // 如果未登录时下拉刷新，可以重置状态或显示提示
        setState(() {
          _user = null;
          _error = null;
          _isInitialized = true; // 确保显示登录提示
          _isLoadingData = false;
          _hasAttemptedInitialLoad = false; // 允许下次可见时重新尝试加载
        });
      }
    } catch (e) {
      print("ProfileScreen: Error during refresh: $e");
      if (mounted) {
        setState(() {
          _error = '刷新失败: $e';
          _isLoadingData = false;
        });
      }
    }
    // 确保加载状态最终被设置为 false
    // if (mounted && _isLoadingData) {
    //   setState(() => _isLoadingData = false);
    // }
  }


  // --- 显示编辑用户名的对话框 (逻辑不变) ---
  void _showEditProfileDialog(User user, BuildContext context) {
    // 使用 listen: false 因为这是触发一个动作
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    EditDialog.show(
      context: context,
      title: '修改用户名',
      initialText: user.username,
      hintText: '请输入新的用户名',
      maxLines: 1,
      iconData: Icons.person_outline,
      onSave: (newUsername) async {
        if (newUsername.trim().isEmpty) {
          if (mounted) AppSnackBar.showWarning(context, '用户名不能为空');
          return;
        }
        if (newUsername.trim() == user.username) {
          return;
        }

        try {
          await _userService.updateUserProfile(username: newUsername.trim());
          if (mounted) {
            AppSnackBar.showSuccess(context, '用户名更新成功');
            // 触发 AuthProvider 刷新，它会更新 currentUser 并通知监听者
            await authProvider.refreshUserState();
            // ProfileScreen 的 build 方法会因为 watch 而重建，使用新的用户信息
            // 无需手动调用 _loadUserProfile
          }
        } catch (e) {
          if (mounted) {
            AppSnackBar.showError(context, '更新失败：$e');
          }
        }
      },
    );
  }

  // --- 显示帮助与反馈页面 (逻辑不变) ---
  void _showHelpAndFeedback() async {
    const String feedbackUrl = 'https://xingsu.fun';
    try {
      final uri = Uri.parse(feedbackUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          AppSnackBar.showError(context, '无法打开反馈页面');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '打开反馈页面时出错：$e');
      }
    }
  }

  // --- 显示退出登录确认对话框 (逻辑不变) ---
  void _showLogoutDialog(BuildContext context) {
    // 使用 listen: false 因为这是触发一个动作
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
        await authProvider.signOut(); // AuthProvider 处理登出并通知
        // ProfileScreen 的 build 会因为 watch 而重建，显示登录提示
        if (mounted) {
          // 登出后重置本页面的状态，以便下次登录时能正确加载
          setState(() {
            _user = null;
            _error = null;
            _isInitialized = false; // 需要重新初始化
            _isLoadingData = false;
            _hasAttemptedInitialLoad = false; // 允许重新尝试首次加载
          });
          NavigationUtils.navigateToHome(context, tabIndex: 0);
        }
      },
    );
  }

  // --- 获取菜单项列表 ---
  List<ProfileMenuItem> _getMenuItems(AuthProvider authProvider, User? currentUser) {
    // 直接使用传入的 authProvider 和 currentUser
    return [
      if (authProvider.isAdmin)
        ProfileMenuItem(
          icon: Icons.admin_panel_settings,
          title: '管理员面板',
          route: AppRoutes.adminDashboard,
        ),
      ProfileMenuItem(
        icon: Icons.people_outline,
        title: '我的关注',
        route: '',
        onTap: () {
          // 使用从 build 方法传递下来的 currentUser
          if (currentUser != null) {
            NavigationUtils.pushNamed(
              context,
              AppRoutes.userFollows,
              arguments: {
                'userId': currentUser.id,
                'username': currentUser.username,
                'initialShowFollowing': true,
              },
            );
          } else {
            if (mounted) {
              AppSnackBar.showError(context, '无法加载用户数据');
            }
          }
        },
      ),
      // ... 其他菜单项保持不变，确保它们不依赖于旧的 _user 状态变量 ...
      ProfileMenuItem(
          icon: Icons.games_outlined, title: '我的游戏', route: AppRoutes.myGames),
      ProfileMenuItem(
          icon: Icons.forum_outlined, title: '我的帖子', route: AppRoutes.myPosts),
      ProfileMenuItem(
          icon: Icons.collections_bookmark_outlined,
          title: '我的收藏',
          route: AppRoutes.myCollections),
      ProfileMenuItem(
          icon: Icons.calendar_today_outlined,
          title: '签到',
          route: AppRoutes.checkin),
      ProfileMenuItem(
          icon: Icons.favorite_border,
          title: '我的喜欢',
          route: AppRoutes.favorites),
      ProfileMenuItem(
          icon: Icons.history, title: '浏览历史', route: AppRoutes.history),
      ProfileMenuItem(
        icon: Icons.share_outlined,
        title: '分享应用',
        route: '',
        onTap: () {
          if (mounted) AppSnackBar.showInfo(context, '分享功能开发中');
        },
      ),
      ProfileMenuItem(
        icon: Icons.help_outline,
        title: '帮助与反馈',
        route: '',
        onTap: _showHelpAndFeedback,
      ),
      ProfileMenuItem(
        icon: Icons.settings,
        title: '设置',
        route: AppRoutes.settingPage,
      ),
    ];
  }

  // --- 处理头像上传状态变化的回调 ---
  void _handleUploadStateChanged(bool isLoading) {
    print("ProfileScreen: Avatar upload state changed to $isLoading");
    // 更新加载状态以防止下拉刷新等冲突操作
    if (mounted && _isLoadingData != isLoading) {
      // 使用 microtask 避免在 build 过程中 setState
      Future.microtask(() {
        if(mounted) {
          setState(() {
            _isLoadingData = isLoading; // 更新本 Widget 的加载状态
          });
        }
      });
    }
  }

  // --- 处理头像上传成功的回调 ---
  // --- 处理头像上传成功的回调 ---
  Future<void> _handleUploadSuccess(BuildContext context) async {
    print("ProfileScreen: Avatar upload succeeded, refreshing user state...");
    // 使用 listen: false 因为这是触发一个动作
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!mounted) return;

    // 可选：如果你希望在 Provider 刷新期间也显示加载动画，
    // 可以保持 _isLoadingData 为 true 或在这里再次设置为 true。
    // 但通常 _handleUploadStateChanged(true) 已经设置了。

    try {
      // 触发 AuthProvider 刷新
      await authProvider.refreshUserState();
      print("ProfileScreen: AuthProvider refresh completed after upload.");

      // *** 关键修复：在刷新成功后，将本 Widget 的加载状态设为 false ***
      // 使用 Future.microtask 确保在当前 build 帧结束后执行 setState
      Future.microtask(() {
        if (mounted && _isLoadingData) { // 检查是否还在加载状态
          setState(() {
            _isLoadingData = false;
          });
          print("ProfileScreen: _isLoadingData reset to false after successful refresh.");
        }
      });
      // 这会触发一次新的 build，这次 _isLoadingData 是 false，
      // 并且 authProvider 已经有了新的用户数据，UI 就能正确显示了。

    } catch (e) {
      print("ProfileScreen: Error during refresh after upload: $e");
      if (mounted) {
        AppSnackBar.showError(context, '刷新用户信息失败: $e');
        // *** 同样，在刷新失败后也要重置加载状态 ***
        Future.microtask(() {
          if (mounted && _isLoadingData) { // 检查是否还在加载状态
            setState(() {
              _isLoadingData = false;
            });
            print("ProfileScreen: _isLoadingData reset to false after refresh error.");
          }
        });
      }
    }
    // 注意：不需要在 finally 里设置，因为 try 和 catch 都处理了
  }
  // --- 主构建方法 ---
  @override
  Widget build(BuildContext context) {
    print("ProfileScreen: build method triggered. Visible: $_isVisible, Initialized: $_isInitialized, Loading: $_isLoadingData");

    // *** 使用 context.watch 获取并监听 AuthProvider ***
    final authProvider = context.watch<AuthProvider>();
    // 获取当前用户数据（可能是 null）
    final User? currentUser = authProvider.currentUser;

    // 获取设备和布局信息
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool useDesktopLayout = isDesktop && screenSize.width > 900;

    return VisibilityDetector(
      key: visibilityKey, // 使用定义的 Key
      onVisibilityChanged: (VisibilityInfo info) {
        final bool currentlyVisible = info.visibleFraction > 0;
        // print("ProfileScreen: Visibility changed. Visible fraction: ${info.visibleFraction}. CurrentlyVisible: $currentlyVisible");

        if (currentlyVisible != _isVisible) {
          print("ProfileScreen: Visibility state changing to $currentlyVisible");
          // 使用 microtask 确保 setState 在 build 之后执行
          Future.microtask(() {
            if (mounted) {
              // 更新可见状态
              setState(() {
                _isVisible = currentlyVisible;
              });

              if (_isVisible) {
                print("ProfileScreen: Became visible.");
                // 变得可见时，尝试触发首次加载（如果条件满足）
                _triggerInitialLoad(context);
              } else {
                print("ProfileScreen: Became hidden.");
              }
            } else {
              // 如果 unmounted，只更新变量，不调用 setState
              _isVisible = currentlyVisible;
            }

          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          title: '个人中心',
          actions: const [], // 移除旧的设置按钮
        ),
        // 使用 RefreshIndicator 包裹 Body
        body: RefreshIndicator(
          onRefresh: () => _refreshProfile(context), // 下拉刷新回调
          child: _buildProfileContent(context, authProvider, currentUser, useDesktopLayout), // 构建主体内容
        ),
        floatingActionButton: _buildFloatButtons(context),
      ),
    );
  }

  // --- 构建悬浮按钮 ---
  Widget _buildFloatButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
      child: FloatingActionButtonGroup(
        spacing: 16.0,
        alignment: MainAxisAlignment.end,
        children: [
          GenericFloatingActionButton(
            icon: Icons.settings_outlined,
            onPressed: () => NavigationUtils.pushNamed(context, AppRoutes.settingPage),
            heroTag: "profile_setting_fab",
            tooltip: "设置", // 移除测试字样
          )
        ],
      ),
    );
  }

  // --- 构建 Profile 主体内容的逻辑 ---
  Widget _buildProfileContent(
      BuildContext context,
      AuthProvider authProvider,
      User? currentUser, // 直接使用来自 watch 的 currentUser
      bool useDesktopLayout,
      ) {

    // --- 状态判断 ---

    // 1. 用户未登录 (由 authProvider.isLoggedIn 驱动)
    if (!authProvider.isLoggedIn) {
      print("ProfileScreen BuildContent: User not logged in.");
      // 重置状态以便下次登录时加载
      if (_isInitialized || _user != null) {
        Future.microtask(() {
          if(mounted){
            setState(() {
              _user = null;
              _error = null;
              _isInitialized = false; // 需要重新初始化
              _isLoadingData = false;
              _hasAttemptedInitialLoad = false; // 允许重新尝试
            });
          }
        });
      }
      return FadeInSlideUpItem(
        duration: const Duration(milliseconds: 300),
        child: LoginPromptWidget(isDesktop: useDesktopLayout),
      );
    }

    // 用户已登录，继续后续判断

    // 2. 尚未初始化 (等待 VisibilityDetector 触发首次加载或加载中)
    // _isInitialized 在 _triggerInitialLoad 开始时或失败/成功后设为 true
    // _isLoadingData 在 _loadUserProfile 开始时设为 true，结束时设为 false
    if (!_isInitialized || _isLoadingData) {
      // 如果正在加载，显示加载中
      if (_isLoadingData) {
        print("ProfileScreen BuildContent: Loading data...");
        return LoadingWidget.fullScreen(message: "正在加载个人信息...");
      }
      // 如果尚未初始化（但已登录），说明 triggerInitialLoad 可能还未完成或未开始
      // 显示一个等待状态，或者如果确定 trigger 已经调用但 load 还没开始，也显示 Loading
      print("ProfileScreen BuildContent: Not initialized yet or waiting for load to start...");
      // 通常 VisibilityDetector 触发后会很快进入 Loading 状态，这个状态可能短暂出现
      return FadeInItem(child: LoadingWidget.fullScreen(message: "准备加载个人信息..."));
    }


    // 3. 加载出错 (_isInitialized 为 true, _isLoadingData 为 false)
    if (_error != null) {
      print("ProfileScreen BuildContent: Error occurred: $_error");
      return InlineErrorWidget(
        errorMessage: _error!,
        onRetry: () => _refreshProfile(context), // 重试按钮触发刷新
      );
    }

    // 4. 加载成功，但用户数据为空 (理论上不应发生，除非 Provider 状态异常)
    // currentUser 是从 authProvider.currentUser 直接获取的
    if (currentUser == null) {
      print("ProfileScreen BuildContent: Data loaded successfully, but currentUser is null.");
      // 可能是 AuthProvider 内部状态问题，显示错误并允许重试
      return FadeInSlideUpItem(
          duration: const Duration(milliseconds: 300),
          child: InlineErrorWidget(
            errorMessage: "无法获取用户信息，请尝试刷新。", // 优化错误信息
            onRetry: () => _refreshProfile(context),
          )
      );
    }

    // 5. 数据加载成功，显示用户信息
    print("ProfileScreen BuildContent: Data loaded, building profile layout for ${currentUser.username}.");
    // final user = _user!; // 现在使用 currentUser
    final menuItems = _getMenuItems(authProvider, currentUser); // 传递 currentUser

    // --- 根据布局选择渲染并应用动画 ---
    if (useDesktopLayout) {
      // --- 桌面布局 ---
      return Padding(
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
                  user: currentUser, // 使用 currentUser
                  onEditProfile: () => _showEditProfileDialog(currentUser, context),
                  onLogout: () => _showLogoutDialog(context), // 移除 authProvider 参数
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
      );
    } else {
      // --- 移动端布局 ---
      // 使用 ListView 替代 SingleChildScrollView + Column 以获得更好的滚动性能和视口外的懒渲染
      return ListView( // 改用 ListView
        physics: const AlwaysScrollableScrollPhysics(), // 允许在内容不足一屏时也能滚动（触发刷新）
        children: [
          FadeInSlideUpItem(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 100),
            child: MobileProfileHeader(
              user: currentUser, // 使用 currentUser
              onEditProfile: () => _showEditProfileDialog(currentUser, context),
              onLogout: () => _showLogoutDialog(context), // 移除 authProvider 参数
              onUploadStateChanged: _handleUploadStateChanged,
              onUploadSuccess: () => _handleUploadSuccess(context),
            ),
          ),
          FadeInSlideUpItem(
            duration: const Duration(milliseconds: 450),
            delay: const Duration(milliseconds: 200),
            child: MobileProfileMenuList(
              menuItems: menuItems,
            ),
          ),
          const SizedBox(height: 80), // 增加底部空间，避免被悬浮按钮遮挡
        ],
      );
    }
  }
}
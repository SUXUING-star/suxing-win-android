// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:visibility_detector/visibility_detector.dart'; // <--- 引入懒加载库
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/screen/profile/layout/models/profile_menu_item.dart';
import 'package:url_launcher/url_launcher.dart'; // 用于帮助与反馈
import '../../models/user/user.dart';
import '../../providers/auth/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/main/user/user_service.dart';
import '../../utils/device/device_utils.dart';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/profile/layout/mobile/mobile_profile_header.dart';
import '../../widgets/components/screen/profile/layout/mobile/mobile_profile_menu_list.dart';
import '../../widgets/components/screen/profile/layout/desktop/desktop_profile_card.dart';
import '../../widgets/components/screen/profile/layout/desktop/desktop_menu_grid.dart';
import '../../widgets/ui/common/error_widget.dart'; // <--- 引入 ErrorWidget
import '../../widgets/ui/common/login_prompt_widget.dart'; // <--- 引入登录提示
import '../../widgets/ui/common/loading_widget.dart'; // <--- 引入 LoadingWidget
import '../../widgets/ui/dialogs/edit_dialog.dart'; // 引入编辑对话框
import '../../widgets/ui/dialogs/confirm_dialog.dart'; // 引入确认对话框

class ProfileScreen extends StatefulWidget {
  // 接收 Key
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  // --- 数据状态 ---
  User? _user; // 用户信息
  String? _error; // 错误信息

  // --- 懒加载核心状态 ---
  bool _isInitialized = false; // 是否已完成首次加载
  bool _isVisible = false; // 当前 Widget 是否可见
  bool _isLoadingData = false; // 是否正在进行加载操作 (首次或刷新)
  // --- 结束懒加载状态 ---

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {

    super.dispose();
  }

  // --- 核心：触发首次数据加载 ---
  void _triggerInitialLoad() {
    // 仅在 Widget 变得可见且尚未初始化时执行
    if (_isVisible && !_isInitialized) {

      // 标记为已初始化（即使加载失败也算初始化过一次）
      // 注意：在 _loadUserProfile 开始时再标记 _isLoadingData = true
      _isInitialized = true;
      _loadUserProfile(); // 调用实际加载方法
    }
  }

  // --- 加载用户配置文件的核心方法 ---
  Future<void> _loadUserProfile() async {
    // 防止重复加载
    if (_isLoadingData) {
      return;
    }

    // 检查是否登录
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      // 如果未登录，也算“初始化”完成（显示登录提示），但没有加载数据
      if (mounted && !_isInitialized) {
        // 确保在 build 循环外更新状态
        Future.microtask(() {
          if (mounted) setState(() => _isInitialized = true);
        });
      }
      return; // 直接返回，后续 build 会处理未登录状态
    }

    if (!mounted) return; // 检查 Widget 是否还在树中

    setState(() {
      _isLoadingData = true; // 开始加载
      _error = null; // 清除旧错误
    });

    try {
      // --- 获取用户数据 ---
      // 使用 .first 获取第一个事件，假设流会立即或很快发出数据
      // 如果流可能长时间无数据，考虑用 .listen 并管理 subscription
      final user = await _userService.getCurrentUserProfile().first;

      if (!mounted) return; // 异步操作后再次检查

      // 更新状态
      setState(() {
        _user = user; // 保存用户数据
        _isLoadingData = false; // 加载完成
      });
    } catch (e, s) {
      if (!mounted) return;
      setState(() {
        _error = '加载个人信息失败: $e'; // 设置错误信息
        _isLoadingData = false; // 加载失败
        _user = null; // 清空用户数据
      });
    }
  }

  // --- 刷新用户配置文件 ---
  Future<void> _refreshProfile() async {
    // 防止重复刷新
    if (_isLoadingData) {
      return;
    }
    if (!mounted) return;


    // (可选) 清除相关缓存
    try {
      await _userService.clearExperienceProgressCache();
    } catch (e) {
    }

    // 直接调用加载方法来刷新
    await _loadUserProfile();
  }

  // --- 解析错误信息中的剩余秒数 (逻辑不变) ---
  int parseRemainingSecondsFromError(String errorMsg) {
    final RegExp regex = RegExp(r'(\d+)'); // 查找数字
    final match = regex.firstMatch(errorMsg);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '60') ?? 60; // 尝试解析，失败返回60
    }
    return 60; // 默认60秒
  }

  // --- 显示编辑用户名的对话框 (逻辑不变) ---
  void _showEditProfileDialog(User user) {
    EditDialog.show(
      // 使用通用编辑对话框
      context: context,
      title: '修改用户名',
      initialText: user.username,
      hintText: '请输入新的用户名',
      maxLines: 1,
      iconData: Icons.person_outline,
      onSave: (newUsername) async {
        // 保存回调
        try {
          // 简单验证
          if (newUsername.trim().isEmpty) {
            if (mounted)
              AppSnackBar.showWarning(context, '用户名不能为空');

            return;
          }
          if (newUsername.trim() == user.username) {
            return; // 名称未改变，不执行操作
          }

          // 调用服务更新用户名
          await _userService.updateUserProfile(username: newUsername.trim());
          // 更新成功后重新加载个人资料
          await _loadUserProfile();

          if (mounted) {
            AppSnackBar.showSuccess(context, '用户名更新成功');

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
    const String feedbackUrl = 'https://xingsu.fun'; // 替换为你的反馈 URL
    try {
      final uri = Uri.parse(feedbackUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication); // 在外部浏览器打开
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
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    CustomConfirmDialog.show(
      // 使用通用确认对话框
      context: context,
      title: '退出登录',
      message: '您确定要退出当前账号吗？',
      confirmButtonText: '确认退出',
      cancelButtonText: '取消',
      confirmButtonColor: Colors.red, // 红色表示危险操作
      iconData: Icons.logout, // 退出图标
      iconColor: Colors.orange, // 图标颜色
      onConfirm: () async {
        // 确认回调
        // 执行退出登录操作
        authProvider.signOut();
        // 退出后通常导航到首页或其他页面
        if (mounted) {
          NavigationUtils.navigateToHome(context, tabIndex: 0); // 导航到首页第一个 Tab
        }
      },
    );
  }

  // --- 获取菜单项列表 (逻辑不变) ---
  List<ProfileMenuItem> _getMenuItems() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // 返回菜单项列表
    return [
      // 仅管理员可见
      if (authProvider.isAdmin)
        ProfileMenuItem(
          icon: Icons.admin_panel_settings,
          title: '管理员面板',
          route: AppRoutes.adminDashboard,
        ),
      ProfileMenuItem(
        icon: Icons.people_outline,
        title: '我的关注',
        route: '', // 使用 onTap 自定义导航
        onTap: () {
          // 确保用户数据已加载
          if (_user != null) {
            NavigationUtils.pushNamed(
              context,
              AppRoutes.userFollows, // 假设这是关注/粉丝页面的路由
              arguments: {
                // 传递必要的参数
                'userId': _user!.id,
                'username': _user!.username,
                'initialShowFollowing': true, // 例如，默认显示关注列表
              },
            );
          } else {
            if (mounted)
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('无法加载用户数据')));
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
        route: '', // 使用 onTap
        onTap: () {
          if (mounted)
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('分享功能开发中')));
        },
      ),
      ProfileMenuItem(
        icon: Icons.help_outline,
        title: '帮助与反馈',
        route: '', // 使用 onTap
        onTap: _showHelpAndFeedback, // 调用显示反馈页面的方法
      ),
    ];
  }

  // --- 处理头像上传状态变化的回调 (逻辑不变，但可能需要更新 _isLoadingData) ---
  void _handleUploadStateChanged(bool isLoading) {
    print("ProfileScreen: Upload state changed to $isLoading");
    // 如果子组件（头像编辑器）开始/结束加载，也更新本页面的加载状态
    // 这有助于防止在上传头像时用户执行其他加载操作（如下拉刷新）
    if (mounted) {
      setState(() {
        _isLoadingData = isLoading;
      });
    }
  }

  // --- 处理头像上传成功的回调 (逻辑不变) ---
  Future<void> _handleUploadSuccess() async {
    print("ProfileScreen: Upload succeeded, reloading profile...");
    // 上传成功后，重新加载用户配置文件以显示新头像
    if (mounted) {
      await _loadUserProfile(); // 调用加载方法
    }
  }

  // --- 主构建方法 ---
  @override
  Widget build(BuildContext context) {
    // 获取认证 Provider，但不监听变化（只在需要时读取）
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 使用 VisibilityDetector 实现懒加载
    return VisibilityDetector(
      key: Key('profile_screen_visibility'), // 唯一 Key
      onVisibilityChanged: (VisibilityInfo info) {
        final bool currentlyVisible = info.visibleFraction > 0;
        if (currentlyVisible != _isVisible) {
          // 使用 microtask 确保 setState 在 build 之后执行
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _isVisible = currentlyVisible;
              });
            } else {
              _isVisible = currentlyVisible; // 更新变量
            }

            if (_isVisible) {
              // 变得可见时，尝试触发加载
              _triggerInitialLoad();

              // 检查登录状态变化：如果可见时发现未登录，但之前有用户数据，则重置状态
              if (_isInitialized && !authProvider.isLoggedIn && _user != null) {
                print(
                    "ProfileScreen: User logged out while visible, resetting state.");
                if (mounted) {
                  setState(() {
                    _isInitialized = false; // 允许下次登录后重新加载
                    _user = null;
                    _error = null;
                    _isLoadingData = false;
                  });
                }
              }
              // 检查登录状态变化：如果可见时发现已登录，但尚未初始化，尝试加载
              else if (!_isInitialized && authProvider.isLoggedIn) {
                print(
                    "ProfileScreen: User logged in while visible, triggering initial load check.");
                _triggerInitialLoad(); // 尝试加载（如果 isInitialized 仍然是 false）
              }
            }
          });
        }
      },
      // 构建实际的 UI 内容
      child: Scaffold(
        backgroundColor: Colors.transparent, // 背景透明，可能依赖于 MainLayout 的背景
        appBar: CustomAppBar(
          // 使用自定义 AppBar
          title: '个人中心',
          actions: [
            // AppBar 右侧操作按钮
            IconButton(
              icon: Icon(Icons.settings_outlined), // 设置图标
              onPressed: () => NavigationUtils.pushNamed(
                  context, AppRoutes.settings), // 导航到设置页面
              tooltip: '设置',
            ),
          ],
        ),
        // 使用 RefreshIndicator 包裹 Body，支持下拉刷新
        body: RefreshIndicator(
          onRefresh: _refreshProfile, // 绑定刷新回调
          child: _buildProfileContent(context, authProvider), // 构建主体内容
        ),
      ),
    );
  }

  // --- 构建 Profile 主体内容的逻辑 ---
  Widget _buildProfileContent(BuildContext context, AuthProvider authProvider) {
    // 获取屏幕尺寸和设备类型
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    // 定义桌面布局的宽度阈值
    final bool useDesktopLayout = isDesktop && screenSize.width > 900;

    // --- 根据状态决定显示内容 ---

    // State 1: 用户未登录
    if (!authProvider.isLoggedIn) {
      return LoginPromptWidget(isDesktop: useDesktopLayout); // 显示登录提示组件
    }

    // State 2: 尚未初始化 (等待 VisibilityDetector 触发首次加载)
    if (!_isInitialized) {
      return LoadingWidget.inline(message: "等待加载个人信息...");
    }

    // State 3: 正在加载数据 (首次加载或刷新中)
    if (_isLoadingData) {
      return LoadingWidget.inline(message: "正在加载个人信息...");
    }

    // State 4: 加载出错
    if (_error != null) {
      print("ProfileScreen Build: Error occurred, showing ErrorWidget.");
      return InlineErrorWidget(
        errorMessage: _error!,
        onRetry: _refreshProfile, // 重试按钮触发刷新)
      );
    }

    // State 5: 加载成功，但用户数据为空 (理论上已登录不应发生，除非API问题)
    if (_user == null) {
      print(
          "ProfileScreen Build: User data is null after load, showing ErrorWidget.");
      return Center(
        child: InlineErrorWidget(
          errorMessage: "无法获取用户信息，请稍后重试。",
          onRetry: _refreshProfile,
        ),
      );
    }

    // State 6: 数据加载成功，显示用户信息
    print("ProfileScreen Build: Data loaded, building profile layout.");
    final user = _user!; // 确认用户数据非空
    final menuItems = _getMenuItems(); // 获取菜单项

    // 根据布局类型选择渲染桌面或移动端视图
    if (useDesktopLayout) {
      // --- 桌面布局 ---
      return Padding(
        // 整体内边距
        padding: const EdgeInsets.all(24.0),
        child: Row(
          // 左右布局
          crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
          children: [
            // 左侧面板 - 用户资料卡片
            Expanded(
              // 占据一部分空间
              flex: 1, // 比例可以调整
              child: DesktopProfileCard(
                // 使用桌面版卡片组件
                user: user,
                onEditProfile: () => _showEditProfileDialog(user), // 编辑按钮回调
                onLogout: () =>
                    _showLogoutDialog(context, authProvider), // 退出按钮回调
                onUploadStateChanged: _handleUploadStateChanged, // 上传状态回调
                onUploadSuccess: _handleUploadSuccess, // 上传成功回调
              ),
            ),
            SizedBox(width: 24), // 左右面板间距
            // 右侧面板 - 菜单网格
            Expanded(
              // 占据剩余空间
              flex: 2, // 比例可以调整
              child: DesktopMenuGrid(menuItems: menuItems), // 使用桌面版菜单网格组件
            ),
          ],
        ),
      );
    } else {
      // --- 移动端布局 ---
      // 使用 SingleChildScrollView 包裹，确保内容可滚动，且能触发 RefreshIndicator
      return SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(), // 保证总是可以滚动下拉
        child: Column(
          // 垂直排列
          children: [
            // 移动端头部信息组件
            MobileProfileHeader(
              user: user,
              onEditProfile: () => _showEditProfileDialog(user),
              onLogout: () => _showLogoutDialog(context, authProvider),
              onUploadStateChanged: _handleUploadStateChanged,
              onUploadSuccess: _handleUploadSuccess,
            ),
            // 移动端菜单列表组件
            MobileProfileMenuList(
              menuItems: menuItems,
            ),
            SizedBox(height: 20), // 底部留一些空间
          ],
        ),
      );
    }
  }
}

// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/screen/profile/layout/models/profile_menu_item.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user/user.dart';
import '../../providers/auth/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/main/user/user_service.dart';
import '../../services/common/upload/rate_limited_file_upload.dart';
import '../../utils/device/device_utils.dart';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/profile/layout/mobile/mobile_profile_header.dart';
import '../../widgets/components/screen/profile/layout/mobile/mobile_profile_menu_list.dart';
import '../../widgets/components/screen/profile/layout/desktop/desktop_profile_card.dart';
import '../../widgets/components/screen/profile/layout/desktop/desktop_menu_grid.dart';
import '../../widgets/components/dialogs/limiter/avatar_rate_limit_dialog.dart';
import '../../widgets/ui/common/error_widget.dart';
import '../../widgets/ui/common/login_prompt_widget.dart';
import '../../widgets/ui/common/loading_widget.dart';
import '../../widgets/ui/dialogs/edit_dialog.dart'; // 统一的编辑对话框
import '../../widgets/ui/dialogs/confirm_dialog.dart'; // 引入新的确认对话框

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();
  User? _user;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // 读取用户资料的逻辑保持不变
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final user = await _userService.getCurrentUserProfile().first;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProfile() async {
    // 下拉刷新的逻辑保持不变
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 清除经验值缓存以确保数据最新
      await _userService.clearExperienceProgressCache();

      // 重新加载用户资料
      await _loadUserProfile();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    // 选择和上传头像的逻辑保持不变
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
        });

        // 使用限速上传服务
        final avatarUrl = await RateLimitedFileUpload.uploadAvatar(
          File(pickedFile.path),
          maxWidth: 800,
          maxHeight: 800,
          quality: 85,
          oldAvatarUrl: _user?.avatar,
        );

        await _userService.updateUserProfile(avatar: avatarUrl);
        await _loadUserProfile(); // 重新加载确保头像更新

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('头像更新成功')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // 检查是否为速率限制错误
        final errorMsg = e.toString();
        if (errorMsg.contains('头像上传速率超限')) {
          // 解析剩余时间并显示对话框
          final remainingSeconds = parseRemainingSecondsFromError(errorMsg);
          showAvatarRateLimitDialog(context, remainingSeconds);
        } else {
          // 显示常规错误消息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('上传头像失败：$e')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 解析错误信息中的剩余秒数，保持不变
  int parseRemainingSecondsFromError(String errorMsg) {
    final RegExp regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(errorMsg);
    if (match != null) {
      return int.parse(match.group(1) ?? '60');
    }
    return 60; // 默认60秒
  }

  // 显示编辑用户名的对话框（已使用统一的 EditDialog）
  void _showEditProfileDialog(User user) {
    EditDialog.show(
      context: context,
      title: '修改用户名',
      initialText: user.username,
      hintText: '请输入新的用户名',
      maxLines: 1,
      iconData: Icons.person_outline,
      onSave: (newUsername) async {
        try {
          if (newUsername.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('用户名不能为空')),
            );
            return;
          }
          if (newUsername.trim() == user.username) {
            return; // 名称未改变，不执行操作
          }

          await _userService.updateUserProfile(
            username: newUsername.trim(),
          );
          await _loadUserProfile(); // 重新加载个人资料

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('用户名更新成功')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('更新失败：$e')),
            );
          }
        }
      },
    );
  }

  // 显示帮助与反馈页面的逻辑保持不变
  void _showHelpAndFeedback() async {
    const String feedbackUrl = 'https://xingsu.fun'; // 替换为你的反馈 URL
    try {
      if (await canLaunchUrl(Uri.parse(feedbackUrl))) {
        await launchUrl(Uri.parse(feedbackUrl));
      } else {
        if (mounted) { // 异步操作后检查 mounted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('无法打开反馈页面')),
          );
        }
      }
    } catch (e) {
      if (mounted) { // 异步操作后检查 mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开反馈页面时出错：$e')),
        );
      }
    }
  }

  // --- 使用 CustomConfirmDialog 替换旧的 LogoutDialog ---
  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    // 调用 CustomConfirmDialog 的静态 show 方法
    CustomConfirmDialog.show(
      context: context,
      title: '退出登录', // 设置对话框标题
      message: '您确定要退出当前账号吗？', // 设置提示信息
      confirmButtonText: '确认退出', // 确认按钮文字
      cancelButtonText: '取消', // 取消按钮文字
      confirmButtonColor: Colors.red, // 确认按钮颜色（危险操作用红色）
      iconData: Icons.logout, // 使用退出图标
      iconColor: Colors.orange, // 图标颜色
      onConfirm: () async { // 确认按钮的回调，必须是 Future<void> Function()
        // 这里执行原来的退出逻辑
        authProvider.signOut();
        // 确保在主线程上执行导航操作，并检查 mounted
        if (mounted) {
          NavigationUtils.navigateToHome(context, tabIndex: 0);
        }
        // 由于 onConfirm 返回 Future<void>，这里不需要显式返回 Future.value()
      },
      // onCancel 可以不传，默认行为是关闭对话框
      // onCancel: () {
      //   print('用户取消了退出');
      // },
    );
  }
  // --- 结束替换 ---

  // 获取菜单项的逻辑保持不变
  List<ProfileMenuItem> _getMenuItems() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final menuItems = [
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
          if (_user != null) {
            NavigationUtils.pushNamed(
              context,
              AppRoutes.userFollows,
              arguments: {
                'userId': _user!.id,
                'username': _user!.username,
                'initialShowFollowing': true,
              },
            );
          }
        },
      ),
      ProfileMenuItem(
        icon: Icons.games_outlined,
        title: '我的游戏',
        route: AppRoutes.myGames,
      ),
      ProfileMenuItem(
        icon: Icons.forum,
        title: '我的帖子',
        route: AppRoutes.myPosts,
      ),
      ProfileMenuItem(
        icon: Icons.videogame_asset,
        title: '我的收藏',
        route: AppRoutes.myCollections,
      ),
      ProfileMenuItem(
        icon: Icons.calendar_today,
        title: '签到',
        route: AppRoutes.checkin,
      ),
      ProfileMenuItem(
        icon: Icons.favorite,
        title: '我的喜欢',
        route: AppRoutes.favorites,
      ),
      ProfileMenuItem(
        icon: Icons.history,
        title: '浏览历史',
        route: AppRoutes.history,
      ),
      ProfileMenuItem(
        icon: Icons.share,
        title: '分享应用',
        route: '',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('分享功能开发中')),
          );
        },
      ),
      ProfileMenuItem(
        icon: Icons.help_outline,
        title: '帮助与反馈',
        route: '',
        onTap: _showHelpAndFeedback,
      ),
    ];
    return menuItems;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    // 阈值可以根据需要调整
    final bool useDesktopLayout = isDesktop && screenSize.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent, // 或 Theme.of(context).scaffoldBackgroundColor
      appBar: CustomAppBar(
        title: '个人中心',
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => NavigationUtils.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile, // 绑定下拉刷新方法
        child: useDesktopLayout
            ? _buildDesktopContent(context, authProvider)
            : _buildMobileContent(context, authProvider),
      ),
    );
  }

  // 构建桌面布局
  Widget _buildDesktopContent(BuildContext context, AuthProvider authProvider) {
    // 加载状态
    if (_isLoading) {
      return LoadingWidget();
    }

    // 错误状态
    if (_error != null) {
      return CustomErrorWidget( // 使用 components/screen/profile 下的错误组件
        errorMessage: _error!,
        onRetry: _refreshProfile,
      );
    }

    // 未登录或用户数据为空状态
    if (_user == null) {
      if (!authProvider.isLoggedIn) {
        return LoginPromptWidget(isDesktop: true); // 桌面版登录提示
      }
      // 如果已登录但 _user 仍为 null，可能是数据加载问题，显示加载中
      return LoadingWidget();
    }

    // --- 正常显示用户数据 ---
    final user = _user!;
    final menuItems = _getMenuItems();

    return Padding(
      padding: const EdgeInsets.all(24.0), // 桌面端增加外边距
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧面板 - 用户资料卡片
          Expanded(
            flex: 1, // 控制宽度比例
            child: DesktopProfileCard(
              user: user,
              onEditProfile: () => _showEditProfileDialog(user), // 编辑用户名
              onAvatarTap: _pickAndUploadAvatar, // 更换头像
              onLogout: () => _showLogoutDialog(context, authProvider), // 调用更新后的退出方法
            ),
          ),

          SizedBox(width: 24), // 面板间距

          // 右侧面板 - 菜单网格
          Expanded(
            flex: 2, // 控制宽度比例
            child: DesktopMenuGrid(menuItems: menuItems), // 菜单项网格
          ),
        ],
      ),
    );
  }

  // 构建移动端布局
  Widget _buildMobileContent(BuildContext context, AuthProvider authProvider) {
    // 加载状态
    if (_isLoading) {
      return LoadingWidget();
    }

    // 错误状态
    if (_error != null) {
      return CustomErrorWidget( // 使用 components/screen/profile 下的错误组件
        errorMessage: _error!,
        onRetry: _refreshProfile,
      );
    }

    // 未登录或用户数据为空状态
    if (_user == null) {
      if (!authProvider.isLoggedIn) {
        return LoginPromptWidget(); // 移动版登录提示
      }
      return LoadingWidget();
    }

    // --- 正常显示用户数据 ---
    final user = _user!;

    return SingleChildScrollView( // 允许内容滚动
      physics: AlwaysScrollableScrollPhysics(), // 即使内容不满一屏也允许下拉刷新
      child: Column(
        children: [
          // 移动端头部信息
          MobileProfileHeader(
            user: user,
            onEditProfile: () => _showEditProfileDialog(user), // 编辑用户名
            onAvatarTap: _pickAndUploadAvatar, // 更换头像
            onLogout: () => _showLogoutDialog(context, authProvider),
          ),
          // 移动端菜单列表
          MobileProfileMenuList(
            menuItems: _getMenuItems(),
          ),
        ],
      ),
    );
  }
}
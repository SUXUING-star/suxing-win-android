// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user/user.dart';
import '../../providers/auth/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/main/user/user_service.dart';
import '../../services/common/upload/rate_limited_file_upload.dart';
import '../../utils/device/device_utils.dart';
import '../../widgets/common/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/profile/layout/android/profile_header.dart';
import '../../widgets/components/screen/profile/layout/android/profile_menu_list.dart';
import '../../widgets/components/screen/profile/layout/desktop/desktop_profile_card.dart';
import '../../widgets/components/screen/profile/layout/desktop/desktop_menu_grid.dart';
import '../../widgets/components/dialogs/limiter/avatar_rate_limit_dialog.dart';
import '../../widgets/components/screen/profile/error_widget.dart';
import '../../widgets/components/screen/profile/login_prompt_widget.dart';
import '../../widgets/components/screen/profile/loading_widget.dart';
import '../../widgets/components/screen/profile/edit_profile_dialog.dart';
import '../../widgets/components/screen/profile/logout_dialog.dart';

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
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      await _loadUserProfile();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
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
        await _loadUserProfile();

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

  // 辅助解析错误信息中的剩余秒数
  int parseRemainingSecondsFromError(String errorMsg) {
    // 这里应该根据实际的错误消息格式进行解析
    // 假设错误消息格式为 "头像上传速率超限，请在 X 秒后重试"
    final RegExp regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(errorMsg);
    if (match != null) {
      return int.parse(match.group(1) ?? '60');
    }
    return 60; // 默认60秒
  }

  void _showEditProfileDialog(User user) {
    showDialog(
      context: context,
      builder: (dialogContext) => EditProfileDialog(
        user: user,
        onSave: (username) async {
          try {
            await _userService.updateUserProfile(
              username: username,
            );
            await _loadUserProfile();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('个人资料更新成功')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('更新失败：$e')),
            );
          }
        },
      ),
    );
  }

  void _showHelpAndFeedback() async {
    const String feedbackUrl = 'https://suxing.site';
    try {
      if (await canLaunchUrl(Uri.parse(feedbackUrl))) {
        await launchUrl(Uri.parse(feedbackUrl));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开反馈页面')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打开反馈页面时出错：$e')),
      );
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => LogoutDialog(
        onConfirm: () {
          authProvider.signOut();
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        },
      ),
    );
  }

  List<ProfileMenuItem> _getMenuItems() {
    final menuItems = [
      if (Provider.of<AuthProvider>(context, listen: false).isAdmin)
        ProfileMenuItem(
          icon: Icons.admin_panel_settings,
          title: '管理员面板',
          route: AppRoutes.adminDashboard,
        ),
      // 添加我的关注入口
      ProfileMenuItem(
        icon: Icons.people_outline,
        title: '我的关注',
        route: '',
        onTap: () {
          if (_user != null) {
            Navigator.pushNamed(
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
      // 替换为统一的游戏收藏入口
      ProfileMenuItem(
        icon: Icons.videogame_asset,
        title: '我的收藏',
        route: AppRoutes.myGames,
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
        icon: Icons.forum,
        title: '我的帖子',
        route: AppRoutes.myPosts,
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
    final bool useDesktopLayout = isDesktop && screenSize.width > 900;

    return Scaffold(
      appBar: CustomAppBar(
        title: '个人资料',
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: useDesktopLayout
            ? _buildDesktopContent(context, authProvider)
            : _buildMobileContent(context, authProvider),
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context, AuthProvider authProvider) {
    if (_isLoading) {
      return ProfileLoadingWidget();
    }

    if (_error != null) {
      return ProfileErrorWidget(
        message: _error!,
        onRetry: _refreshProfile,
      );
    }

    if (_user == null) {
      if (!authProvider.isLoggedIn) {
        return LoginPromptWidget(isDesktop: true);
      }
      return ProfileLoadingWidget();
    }

    final user = _user!;
    final menuItems = _getMenuItems();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧面板 - 用户资料卡片
          Expanded(
            flex: 1,
            child: DesktopProfileCard(
              user: user,
              onEditProfile: () => _showEditProfileDialog(user),
              onAvatarTap: _pickAndUploadAvatar,
              onLogout: () => _showLogoutDialog(context, authProvider),
            ),
          ),

          SizedBox(width: 24),

          // 右侧面板 - 菜单网格
          Expanded(
            flex: 2,
            child: DesktopMenuGrid(menuItems: menuItems),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context, AuthProvider authProvider) {
    if (_isLoading) {
      return ProfileLoadingWidget();
    }

    if (_error != null) {
      return ProfileErrorWidget(
        message: _error!,
        onRetry: _refreshProfile,
      );
    }

    if (_user == null) {
      if (!authProvider.isLoggedIn) {
        return LoginPromptWidget();
      }
      return ProfileLoadingWidget();
    }

    final user = _user!;

    return SingleChildScrollView(
      child: Column(
        children: [
          ProfileHeader(
            user: user,
            onEditProfile: () => _showEditProfileDialog(user),
            onAvatarTap: _pickAndUploadAvatar,
          ),
          Divider(),
          ProfileMenuList(
            menuItems: _getMenuItems(),
            onLogout: () => authProvider.signOut(),
          ),
        ],
      ),
    );
  }
}
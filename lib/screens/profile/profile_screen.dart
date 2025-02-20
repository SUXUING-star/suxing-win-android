import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user/user.dart';
import '../../providers/auth/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/user_service.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/profile_menu_list.dart';
import '../../utils/upload/file_upload.dart';
import '../../utils/font/font_config.dart';
import '../../widgets/common/custom_app_bar.dart';

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
        maxWidth: 800,  // 限制最大宽度
        maxHeight: 800, // 限制最大高度
        imageQuality: 85, // 压缩质量
      );

      if (pickedFile != null) {
        // 显示加载指示器
        setState(() {
          _isLoading = true;
        });

        // 上传到 OSS
        final avatarUrl = await FileUpload.uploadImage(
          File(pickedFile.path),
          folder: 'avatars',
          maxWidth: 800,
          maxHeight: 800,
          quality: 85,
        );

        // 更新用户资料
        await _userService.updateUserProfile(avatar: avatarUrl);

        // 重新加载用户资料
        await _loadUserProfile();

        // 显示成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('头像更新成功')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传头像失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEditProfileDialog(User user) {
    final TextEditingController usernameController = TextEditingController(text: user.username);

    showDialog(
      context: context,
      builder: (dialogContext) => Builder(
        builder: (builderContext) => AlertDialog(
          title: Text('编辑个人资料'),
          content: TextField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: '用户名',
              hintText: '输入新的用户名',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _userService.updateUserProfile(
                    username: usernameController.text,
                  );
                  await _loadUserProfile();
                  Navigator.of(dialogContext).pop();

                  // Use ScaffoldMessenger of the original context
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('个人资料更新成功')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('更新失败：$e')),
                  );
                }
              },
              child: Text('保存'),
            ),
          ],
        ),
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

  List<ProfileMenuItem> _getMenuItems() {
    final menuItems = [
      if (Provider.of<AuthProvider>(context, listen: false).isAdmin)
        ProfileMenuItem(
          icon: Icons.admin_panel_settings,
          title: '管理员面板',
          route: AppRoutes.adminDashboard,
        ),
      ProfileMenuItem(
        icon: Icons.favorite,
        title: '我的收藏',
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
        child: _buildContent(context, authProvider),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AuthProvider authProvider) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError(context, _error!);
    }

    if (_user == null) {
      if (!authProvider.isLoggedIn) {
        return _buildLoginPrompt(context);
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载用户信息...'),
          ],
        ),
      );
    }

    // 创建一个本地final变量
    final user = _user!;  // 使用感叹号断言_user不为空

    return SingleChildScrollView(
      child: Column(
        children: [
          ProfileHeader(
            user: user,  // 使用本地变量
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
  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshProfile,
            child: Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return SingleChildScrollView( // Added SingleChildScrollView
      child: Center(
        child: Padding( // Added Padding for spacing
          padding: const EdgeInsets.all(16.0), // Adjust padding as needed
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 24),
              Text(
                '还未登录',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '登录后可以体验更多功能',
                textAlign: TextAlign.center, // Added textAlign for better readability
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: FontConfig.defaultFontFamily,
                  fontFamilyFallback: FontConfig.fontFallback,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.login);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '立即登录',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: FontConfig.defaultFontFamily,
                    fontFamilyFallback: FontConfig.fontFallback,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
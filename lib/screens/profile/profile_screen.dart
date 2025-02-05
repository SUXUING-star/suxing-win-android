// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/user_service.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/profile_menu_list.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        await _userService.updateUserProfile(avatar: pickedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传头像失败：$e')),
      );
    }
  }

  void _showEditProfileDialog(User user) {
    final TextEditingController usernameController = TextEditingController(text: user.username);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _userService.updateUserProfile(
                  username: usernameController.text,
                );
                Navigator.of(context).pop();
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
    );
  }

  void _showHelpAndFeedback() async {
    const String feedbackUrl = 'https://suxing.site'; // 替换为实际的反馈页面
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
    return [
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
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('个人资料'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: _userService.getCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildError(context, '加载失败：${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          final user = snapshot.data;
          if (user == null && !authProvider.isLoggedIn) {
            return _buildLoginPrompt(context);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                ProfileHeader(
                  user: user!,
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
        },
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
            onPressed: () {
              // 重试或返回
              Navigator.pop(context);
            },
            child: Text('返回'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('请先登录'),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.login);
            },
            child: Text('去登录'),
          ),
        ],
      ),
    );
  }
}
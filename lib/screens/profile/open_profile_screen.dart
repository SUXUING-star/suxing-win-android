// lib/screens/profile/open_profile_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../services/forum_service.dart';
import '../../models/post.dart';

class OpenProfileScreen extends StatefulWidget {
  final String userId;

  const OpenProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _OpenProfileScreenState createState() => _OpenProfileScreenState();
}

class _OpenProfileScreenState extends State<OpenProfileScreen> {
  final UserService _userService = UserService();
  final ForumService _forumService = ForumService();
  User? _user;
  List<Post>? _recentPosts;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userDoc = await _userService.safegetUserById(widget.userId);
      if (userDoc != null) {
        _user = User.fromJson(userDoc);
      }

      _recentPosts = await _forumService.getRecentUserPosts(widget.userId, limit: 5);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载用户资料失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.username ?? '用户资料'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(),
          Divider(),
          _buildUserInfo(),
          Divider(),
          _buildRecentPosts(),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: _user?.avatar != null
                ? NetworkImage(_user!.avatar!)
                : null,
            child: _user?.avatar == null
                ? Text(_user?.username.substring(0, 1).toUpperCase() ?? '')
                : null,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.username ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text(
                  '创建于 ${_formatDate(_user?.createTime)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('用户信息', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8),
          // 这里可以添加更多非敏感的用户信息
        ],
      ),
    );
  }

  Widget _buildRecentPosts() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('最近发表', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8),
          if (_recentPosts != null && _recentPosts!.isNotEmpty)
            Column(
              children: _recentPosts!.map((post) => _buildPostItem(post)).toList(),
            )
          else
            Text('暂无发表'),
        ],
      ),
    );
  }

  Widget _buildPostItem(Post post) {
    return ListTile(
      title: Text(post.title),
      subtitle: Text(_formatDate(post.createTime)),
      onTap: () {
        // 跳转到帖子详情页面
        Navigator.pushNamed(context, '/forum/post', arguments: post.id);
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
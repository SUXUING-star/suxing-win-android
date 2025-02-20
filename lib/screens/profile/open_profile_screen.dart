// lib/screens/profile/open_profile_screen.dart
import 'package:flutter/material.dart';
import '../../models/user/user.dart';
import '../../services/user_service.dart';
import '../../services/forum_service.dart';
import '../../services/game_service.dart';
import '../../models/post/post.dart';
import '../../models/game/game.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/profile/open/profile_game_card..dart';
import '../../widgets/profile/open/profile_post_card.dart';

class OpenProfileScreen extends StatefulWidget {
  final String userId;

  const OpenProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _OpenProfileScreenState createState() => _OpenProfileScreenState();
}

class _OpenProfileScreenState extends State<OpenProfileScreen> {
  final UserService _userService = UserService();
  final ForumService _forumService = ForumService();
  final GameService _gameService = GameService();

  User? _user;
  List<Post>? _recentPosts;
  List<Game>? _publishedGames;
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
      // 加载用户基本信息
      final userDoc = await _userService.safegetUserById(widget.userId);
      if (userDoc != null) {
        _user = User.fromJson(userDoc);
      }

      // 并行加载帖子和游戏
      final futures = await Future.wait([
        _forumService.getRecentUserPosts(widget.userId, limit: 5),
        _gameService.getGamesPaginated(
          page: 1,
          pageSize: 5,
          sortBy: 'createTime',
          descending: true,
        ),
      ]);

      setState(() {
        _recentPosts = futures[0] as List<Post>;
        _publishedGames = futures[1] as List<Game>;
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
      appBar: CustomAppBar(
        title: _user?.username ?? '用户资料',
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(),
          SizedBox(height: 24),

          // 发布的游戏
          Text(
            '发布的游戏',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          if (_publishedGames != null && _publishedGames!.isNotEmpty)
            ...(_publishedGames!.map((game) => ProfileGameCard(game: game)))
          else
            Text('暂无发布的游戏'),

          SizedBox(height: 24),

          // 发布的帖子
          Text(
            '发布的帖子',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          if (_recentPosts != null && _recentPosts!.isNotEmpty)
            ...(_recentPosts!.map((post) => ProfilePostCard(post: post)))
          else
            Text('暂无发布的帖子'),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: _user?.avatar != null
              ? NetworkImage(_user!.avatar!)
              : null,
          child: _user?.avatar == null
              ? Text(
            _user?.username.substring(0, 1).toUpperCase() ?? '',
            style: TextStyle(fontSize: 24),
          )
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
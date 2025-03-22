// lib/screens/profile/open_profile_screen.dart
import 'package:flutter/material.dart';
import '../../models/user/user.dart';
import '../../services/main/user/user_service.dart';
import '../../services/main/forum/forum_service.dart';
import '../../services/main/game/game_service.dart';
import '../../models/post/post.dart';
import '../../models/game/game.dart';
import '../../widgets/common/appbar/custom_app_bar.dart';
import '../../widgets/common/image/safe_user_avatar.dart';
import '../../utils/device/device_utils.dart';
import '../../widgets/components/screen/profile/open/mobile/profile_game_card.dart';
import '../../widgets/components/screen/profile/open/mobile/profile_post_card.dart';
import '../../widgets/components/button/follow_user_button.dart';

class OpenProfileScreen extends StatefulWidget {
  final String userId;

  const OpenProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _OpenProfileScreenState createState() => _OpenProfileScreenState();
}

class _OpenProfileScreenState extends State<OpenProfileScreen> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final ForumService _forumService = ForumService();
  final GameService _gameService = GameService();

  User? _user;
  List<Post>? _recentPosts;
  List<Game>? _publishedGames;
  bool _isLoading = true;
  String? _error;
  bool _isCurrentUser = false;
  bool _isGridView = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 获取当前登录用户ID
      final currentUserId = await _userService.currentUserId;
      _isCurrentUser = currentUserId == widget.userId;

      // 获取用户信息
      final userInfo = await _userService.safegetUserById(widget.userId);
      if (userInfo != null) {
        _user = User.fromJson(userInfo);
      }

      // 加载用户帖子
      final userPosts = await _forumService.getRecentUserPosts(widget.userId, limit: 5);

      // 加载用户发布的游戏
      final userGames = await _gameService.getGamesPaginated(
        page: 1,
        pageSize: 10,
        sortBy: 'createTime',
        descending: true,
        authorId: widget.userId,
      );

      setState(() {
        _recentPosts = userPosts;
        _publishedGames = userGames;
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
    final isDesktop = DeviceUtils.isDesktop ||
        (DeviceUtils.isTablet(context) && DeviceUtils.isLandscape(context));

    return Scaffold(
      appBar: CustomAppBar(
        title: _user?.username ?? '用户资料',
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: _buildBody(isDesktop),
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载用户资料...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: Text('重新加载'),
            ),
          ],
        ),
      );
    }

    return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // 左侧用户信息
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildUserHeader(),
                  SizedBox(height: 16),
                  _buildUserStatistics(),
                ],
              ),
            ),
          ),
        ),

        // 右侧内容
        Expanded(
          flex: 2,
          child: _buildContentSection(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildUserHeader(),
        _buildContentSection(),
      ],
    );
  }

  Widget _buildUserHeader() {
    if (_user == null) return SizedBox.shrink();

    return Card(
      margin: EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SafeUserAvatar(
              userId: _user?.id,
              avatarUrl: _user?.avatar,
              username: _user?.username ?? '',
              radius: 50,
              enableNavigation: false,
            ),
            SizedBox(height: 12),

            // 用户名和等级
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _user?.username ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getLevelColor(_user?.level ?? 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv.${_user?.level ?? 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),
            Text(
              '${_user?.experience ?? 0} XP',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: 12),
            // 关注和粉丝信息
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFollowInfo('关注', _user?.following.length ?? 0),
                SizedBox(width: 20),
                _buildFollowInfo('粉丝', _user?.followers.length ?? 0),
              ],
            ),

            SizedBox(height: 12),
            Text(
              '创建于 ${_formatDate(_user?.createTime)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: 12),
            if (!_isCurrentUser)
              FollowUserButton(
                userId: widget.userId,
                showIcon: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowInfo(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              icon: Icon(Icons.videogame_asset),
              text: '发布的游戏 ${_publishedGames?.length ?? 0}',
            ),
            Tab(
              icon: Icon(Icons.forum),
              text: '发布的帖子 ${_recentPosts?.length ?? 0}',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGamesContent(),
              _buildPostsContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGamesContent() {
    if (_publishedGames == null || _publishedGames!.isEmpty) {
      return _buildEmptyState('暂无发布的游戏', Icons.videogame_asset);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: _isGridView ? _buildGamesGrid() : _buildGamesList(),
    );
  }

  Widget _buildPostsContent() {
    if (_recentPosts == null || _recentPosts!.isEmpty) {
      return _buildEmptyState('暂无发布的帖子', Icons.forum);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: _buildPostsList(),
    );
  }

  Widget _buildGamesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _publishedGames!.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ProfileGameCard(
            game: _publishedGames![index],
            isGridItem: false,
          ),
        );
      },
    );
  }

  Widget _buildGamesGrid() {
    final crossAxisCount = DeviceUtils.calculateCardsPerRow(context);
    final cardRatio = DeviceUtils.calculateSimpleCardRatio(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: cardRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _publishedGames!.length,
      itemBuilder: (context, index) {
        return ProfileGameCard(
          game: _publishedGames![index],
          isGridItem: true,
        );
      },
    );
  }

  Widget _buildPostsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _recentPosts!.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ProfilePostCard(post: _recentPosts![index]),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
  Widget _buildUserStatistics() {
    if (_user == null) return SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '用户统计',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // 发布游戏统计
            _buildStatRow(
              icon: Icons.videogame_asset,
              title: '发布游戏',
              value: _publishedGames?.length.toString() ?? '0',
              color: Colors.blue,
            ),

            Divider(height: 24),

            // 发布帖子统计
            _buildStatRow(
              icon: Icons.forum,
              title: '发布帖子',
              value: _recentPosts?.length.toString() ?? '0',
              color: Colors.green,
            ),

            Divider(height: 24),

            // 连续签到
            _buildStatRow(
              icon: Icons.calendar_today,
              title: '连续签到',
              value: '${_user?.consecutiveCheckIn ?? 0} 天',
              color: Colors.orange,
            ),

            Divider(height: 24),

            // 累计签到
            _buildStatRow(
              icon: Icons.check_circle_outline,
              title: '累计签到',
              value: '${_user?.totalCheckIn ?? 0} 天',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

// 辅助方法，用于构建统计行
  Widget _buildStatRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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

  Color _getLevelColor(int level) {
    if (level < 5) return Colors.green;
    if (level < 10) return Colors.blue;
    if (level < 20) return Colors.purple;
    if (level < 50) return Colors.orange;
    return Colors.red;
  }
}
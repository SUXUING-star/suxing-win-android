// lib/screens/profile/open_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/constants/user/level_constants.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/badges/safe_user_avatar.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/profile/open/profile_game_card.dart';
import 'package:suxingchahui/widgets/components/screen/profile/open/profile_post_card.dart';
import 'package:suxingchahui/widgets/ui/buttons/follow_user_button.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class OpenProfileScreen extends StatefulWidget {
  final String userId;
  final UserService userService;
  final AuthProvider authProvider;
  final UserFollowService followService;
  final ForumService forumService;
  final GameService gameService;

  const OpenProfileScreen({
    super.key,
    required this.userService,
    required this.gameService,
    required this.authProvider,
    required this.forumService,
    required this.followService,
    required this.userId,
  });

  @override
  _OpenProfileScreenState createState() => _OpenProfileScreenState();
}

class _OpenProfileScreenState extends State<OpenProfileScreen>
    with SingleTickerProviderStateMixin {
  User? _user;
  List<Post>? _recentPosts;
  List<Game>? _publishedGames;
  bool _isLoading = true;
  String? _error;
  bool _isCurrentUser = false;
  bool _isGridView = true;

  late TabController _tabController;
  bool _hasInitializedDependencies = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
      _currentUser = widget.authProvider.currentUser;
    }
    if (_hasInitializedDependencies) {
      _loadUserProfile();
    }
  }

  @override
  void didUpdateWidget(covariant OpenProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentUser != widget.authProvider.currentUser ||
        oldWidget.authProvider.currentUser != widget.authProvider.currentUser) {
      setState(() {
        _currentUser = widget.authProvider.currentUser;
      });
    }
    if (oldWidget.userId != widget.userId) {
      setState(() {});
    }
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
      final String? currentUserId = widget.authProvider.currentUserId;
      final User? currentUser = widget.authProvider.currentUser;
      _isCurrentUser = currentUserId == widget.userId;

      if (_isCurrentUser && currentUser != null) {
        _user = currentUser;
      } else {
        // *** userService开始了它的使命 *** //
        // 这个用户不是你
        _user = await widget.userService.getUserInfoById(widget.userId);
        // *** userService结束了它的使命 *** //
      }

      // *** forumService开始了它的使命 *** //
      // 加载用户帖子
      final userPosts = await widget.forumService.getRecentUserPosts(widget.userId);
      // *** forumService结束了它的使命 *** //

      // *** gameService开始了它的使命 *** //
      // 加载用户发布的游戏
      final userGames = await widget.gameService.getGamesPaginated(
        page: 1,
        pageSize: 10,
        sortBy: 'createTime',
        descending: true,
        authorId: widget.userId,
      );
      // *** gameService结束了它的使命 *** //

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
      return LoadingWidget.fullScreen(message: '正在加载用户资料...');
    }

    if (_error != null) {
      // 错误提示加个动画
      return CustomErrorWidget(
        onRetry: _loadUserProfile,
        errorMessage: _error,
      );
    }

    final contentKey = ValueKey<String>(_user?.id ?? 'loading_finished');

    if (isDesktop) {
      return _buildDesktopLayout(contentKey); // 传递 Key
    } else {
      return _buildMobileLayout(contentKey); // 传递 Key
    }
  }

  Widget _buildDesktopLayout(Key animationKey) {
    // 定义基础延迟和间隔
    const Duration initialDelay = Duration(milliseconds: 100);
    const Duration stagger = Duration(milliseconds: 150);

    return Row(
      key: animationKey, // 应用 Key
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
                  // 用户 Header 动画
                  FadeInSlideUpItem(
                    delay: initialDelay, // 第一个出现
                    child: _buildUserHeader(),
                  ),
                  SizedBox(height: 16),
                  // 用户统计卡片动画
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger, // 稍微延迟
                    child: _buildUserStatistics(),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 右侧内容区动画
        Expanded(
          flex: 2,
          child: FadeInSlideUpItem(
            delay: initialDelay + stagger * 2, // 更晚一点出现
            child: _buildContentSection(), // 内容区的动画是整体的
            // 内部列表/网格的动画在下面处理
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Key animationKey) {
    // 定义基础延迟和间隔
    const Duration initialDelay = Duration(milliseconds: 100);
    const Duration stagger = Duration(milliseconds: 150);

    return Column(
      key: animationKey, // 应用 Key
      children: [
        // 用户 Header 动画
        FadeInSlideUpItem(
          delay: initialDelay,
          child: _buildUserHeader(),
        ),
        // 内容区动画 (TabBar + TabBarView)
        // Expanded 包裹动画组件，确保内容区能正确填充剩余空间
        Expanded(
          child: FadeInSlideUpItem(
            delay: initialDelay + stagger,
            child: _buildContentSection(), // 同样，内部列表/网格动画需单独处理
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeader() {
    if (_user == null) return const SizedBox.shrink();

    // 1. 确定头像在这个屏幕的显示半径
    const double avatarRadiusInProfile =
        50.0; // 这是你在 _buildUserHeader 里给头像设置的半径

    // 2. 计算传递给 SafeUserAvatar 的 memCache 尺寸
    // 这是 OpenProfileScreen 主动为它内部的 SafeUserAvatar 设置的
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int calculatedMemCacheSize =
        (avatarRadiusInProfile * 2 * devicePixelRatio).round();

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
              isAdmin: _user?.isAdmin ?? false,
              isSuperAdmin: _user?.isSuperAdmin ?? false,
              userId: _user?.id,
              avatarUrl: _user?.avatar,
              username: _user?.username ?? '',
              radius: 50,
              enableNavigation: false,
              memCacheWidth: calculatedMemCacheSize,
              memCacheHeight: calculatedMemCacheSize,
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
                currentUser: widget.authProvider.currentUser,
                followService: widget.followService,
                targetUserId: widget.userId,
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
      return const EmptyStateWidget(
          message: '暂无发布的游戏', iconData: Icons.videogame_asset);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: _isGridView ? _buildGamesGrid() : _buildGamesList(),
    );
  }

  Widget _buildPostsContent() {
    if (_recentPosts == null || _recentPosts!.isEmpty) {
      return const EmptyStateWidget(message: '暂无发布的帖子', iconData: Icons.forum);
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
        // 为每个列表项添加动画
        return FadeInSlideUpItem(
          delay: Duration(milliseconds: 50 * index), //  staggered delay
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: ProfileGameCard(
              game: _publishedGames![index],
              isGridItem: false,
            ),
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
        // 为每个网格项添加动画
        return FadeInSlideUpItem(
          delay: Duration(milliseconds: 50 * index), // staggered delay
          child: ProfileGameCard(
            game: _publishedGames![index],
            isGridItem: true,
          ),
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
        // 为每个帖子项添加动画
        return FadeInSlideUpItem(
          delay: Duration(milliseconds: 50 * index), // staggered delay
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ProfilePostCard(post: _recentPosts![index]),
          ),
        );
      },
    );
  }

  Widget _buildUserStatistics() {
    if (_user == null) return const SizedBox.shrink();

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
            color: color.withSafeOpacity(0.1),
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
    return DateTimeFormatter.formatStandard(date);
  }

  Color _getLevelColor(int level) {
    return LevelUtils.getLevelColor(level);
  }
}

// lib/screens/profile/open/open_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game_list_pagination.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/profile/open/open_profile_layout.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';

class OpenProfileScreen extends StatefulWidget {
  final String userId;
  final UserService userService;
  final AuthProvider authProvider;
  final UserFollowService followService;
  final PostService postService;
  final GameService gameService;
  final UserInfoProvider infoProvider;
  final WindowStateProvider windowStateProvider;

  const OpenProfileScreen({
    super.key,
    required this.userService,
    required this.gameService,
    required this.authProvider,
    required this.postService,
    required this.followService,
    required this.infoProvider,
    required this.userId,
    required this.windowStateProvider,
  });

  @override
  _OpenProfileScreenState createState() => _OpenProfileScreenState();
}

class _OpenProfileScreenState extends State<OpenProfileScreen>
    with SingleTickerProviderStateMixin {
  User? _targetUser;
  List<Post>? _recentPosts;
  List<Game>? _publishedGames;
  bool _isLoading = true;
  String? _error;
  bool _isCurrentUser = false;
  bool _isGridView = true;

  late TabController _tabController;
  bool _hasInitializedDependencies = false;
  String? _currentUserId;

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
      _currentUserId = widget.authProvider.currentUserId;
    }
    if (_hasInitializedDependencies) {
      _loadUserProfile();
    }
  }

  @override
  void didUpdateWidget(covariant OpenProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentUserId != widget.authProvider.currentUserId ||
        oldWidget.authProvider.currentUserId !=
            widget.authProvider.currentUserId) {
      setState(() {
        _currentUserId = widget.authProvider.currentUserId;
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

  void _handleFollowChanged() {
    if (mounted) {
      _loadUserProfile();
    }
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
        _targetUser = currentUser;
      } else {
        // 这个用户不是你
        _targetUser = await widget.userService.getUserInfoById(widget.userId);
      }

      // 加载用户帖子
      final userPosts =
          await widget.postService.getRecentUserPosts(widget.userId);

      // 加载用户发布的游戏
      final GameListPagination userGamesWithPagination =
          await widget.gameService.getGamesPaginatedWithInfo(
        page: 1,
        sortBy: 'createTime',
        descending: true,
        authorId: widget.userId,
      );

      setState(() {
        _recentPosts = userPosts;
        _publishedGames = userGamesWithPagination.games;
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
        title: _isLoading ? '加载中...' : (_targetUser?.username ?? '用户资料'),
        actions: [
          // 只有在数据加载完毕且没有错误时才显示切换按钮
          if (!_isLoading && _error == null)
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              tooltip: _isGridView ? '列表视图' : '网格视图',
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                }
              },
            ),
        ],
      ),
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "少女正在偷看中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }

    if (_error != null) {
      return CustomErrorWidget(
        onRetry: _loadUserProfile,
        errorMessage: _error,
      );
    }
    if (_targetUser == null) {
      return CustomErrorWidget(
        errorMessage: "目标用户不存在",
      );
    }

    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = DeviceUtils.isDesktopInThisWidth(screenWidth);
        return OpenProfileLayout(
          targetUser: _targetUser!,
          recentPosts: _recentPosts,
          publishedGames: _publishedGames,
          isGridView: _isGridView,
          tabController: _tabController,
          authProvider: widget.authProvider,
          isDesktop: isDesktop,
          screenWidth: screenWidth,
          infoProvider: widget.infoProvider,
          followService: widget.followService,
          // 传入 UserFollowService
          onFollowChanged: _handleFollowChanged, // 传入关注变化的回调
        );
      },
    );
  }
}

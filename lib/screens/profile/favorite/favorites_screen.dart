// lib/screens/profile/favorite/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/game/game_list_pagination.dart'; // 导入 game_list_pagination
import 'package:suxingchahui/models/post/post_list_pagination.dart'; // 导入 post_list_pagination
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/tabs/custom_segmented_control_tab_bar.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/components/screen/favorite/game_likes_layout.dart';
import 'package:suxingchahui/widgets/components/screen/favorite/post_favorites_layout.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackBar.dart';

class FavoritesScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final GameService gameService;
  final PostService postService;
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  final WindowStateProvider windowStateProvider;
  const FavoritesScreen({
    super.key,
    required this.authProvider,
    required this.gameService,
    required this.postService,
    required this.followService,
    required this.infoProvider,
    required this.windowStateProvider,
  });

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabTitles = ['游戏', '帖子'];

  List<Game> _favoriteGames = [];
  PaginationData? _gamePaginationData;
  bool _isLoadingGames = false;
  bool _isLoadingMoreGames = false;
  String? _gameError;
  int _gamePage = 1;

  List<Post> _favoritePosts = [];
  PaginationData? _postPaginationData;
  bool _isLoadingPosts = false;
  bool _isLoadingMorePosts = false;
  String? _postError;
  int _postPage = 1;

  final ScrollController _gameScrollController = ScrollController();
  final ScrollController _postScrollController = ScrollController();

  User? _currentUser;
  String? _prevUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    _gameScrollController
        .addListener(() => _handleScroll(_gameScrollController, 0));
    _postScrollController
        .addListener(() => _handleScroll(_postScrollController, 1));
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _gameScrollController.dispose();
    _postScrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      return;
    }
    _loadFavoritesForTab(_tabController.index);
  }

  void _handleScroll(ScrollController controller, int tabIndex) {
    if (controller.position.pixels >=
        controller.position.maxScrollExtent * 0.9) {
      if (tabIndex == 0 &&
          !_isLoadingMoreGames &&
          (_gamePaginationData?.hasNextPage() ?? false)) {
        _loadMoreGames();
      } else if (tabIndex == 1 &&
          !_isLoadingMorePosts &&
          (_postPaginationData?.hasNextPage() ?? false)) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadFavoritesForTab(int tabIndex) async {
    final currentUserId = widget.authProvider.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      _resetDataForLoggedOutUser();
      return;
    }

    if (tabIndex == 0 && !_isLoadingGames && _favoriteGames.isEmpty) {
      _fetchGames(isRefresh: true);
    } else if (tabIndex == 1 && !_isLoadingPosts && _favoritePosts.isEmpty) {
      _fetchPosts(isRefresh: true);
    }
  }

  void _resetDataForLoggedOutUser() {
    if (mounted) {
      setState(() {
        _favoriteGames = [];
        _gamePaginationData = null;
        _isLoadingGames = false;
        _isLoadingMoreGames = false;
        _gameError = null;
        _gamePage = 1;

        _favoritePosts = [];
        _postPaginationData = null;
        _isLoadingPosts = false;
        _isLoadingMorePosts = false;
        _postError = null;
        _postPage = 1;
      });
    }
  }

  Future<void> _fetchGames({bool isRefresh = false}) async {
    if (!mounted || (_isLoadingGames && !isRefresh)) return;

    if (isRefresh) _gamePage = 1;

    setState(() {
      _isLoadingGames = true;
      _gameError = null;
      if (isRefresh) {
        _favoriteGames = [];
        _gamePaginationData = null;
      }
    });

    try {
      final currentUserId = widget.authProvider.currentUserId;
      if (currentUserId == null || currentUserId.isEmpty) {
        _resetDataForLoggedOutUser();
        return;
      }

      final GameListPagination gameListResult =
          await widget.gameService.getUserLikeGames(
        page: _gamePage,
      );

      if (!mounted) return;
      setState(() {
        if (isRefresh) {
          _favoriteGames = gameListResult.games;
        } else {
          _favoriteGames.addAll(gameListResult.games);
        }
        _gamePaginationData = gameListResult.pagination;
        _isLoadingGames = false;
        _gameError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingGames = false;
        _gameError = '加载收藏游戏失败: ${e.toString().split(':').last.trim()}';
      });
      AppSnackBar.showError('加载收藏游戏失败');
    }
  }

  Future<void> _loadMoreGames() async {
    if (!mounted ||
        _isLoadingMoreGames ||
        !(_gamePaginationData?.hasNextPage() ?? false)) {
      return;
    }

    _gamePage++;
    setState(() {
      _isLoadingMoreGames = true;
    });

    try {
      final currentUserId = widget.authProvider.currentUserId;
      if (currentUserId == null || currentUserId.isEmpty) {
        _gamePage--;
        _resetDataForLoggedOutUser();
        return;
      }

      final GameListPagination gameListResult =
          await widget.gameService.getUserLikeGames(
        page: _gamePage,
      );

      if (!mounted) return;
      setState(() {
        _favoriteGames.addAll(gameListResult.games);
        _gamePaginationData = gameListResult.pagination;
        _isLoadingMoreGames = false;
      });
    } catch (e) {
      if (!mounted) return;
      _gamePage--;
      setState(() {
        _isLoadingMoreGames = false;
        _gameError = '加载更多收藏游戏失败: ${e.toString().split(':').last.trim()}';
      });
      AppSnackBar.showError('加载更多收藏游戏失败');
    }
  }

  Future<void> _toggleGameLike(String gameId) async {
    try {
      await widget.gameService.toggleLike(gameId, true); // 妈的，传递旧状态为 true
      await _fetchGames(isRefresh: true);
    } catch (e) {
      AppSnackBar.showError('取消收藏失败: ${e.toString()}');
    }
  }

  Future<void> _fetchPosts({bool isRefresh = false}) async {
    if (!mounted || (_isLoadingPosts && !isRefresh)) return;

    if (isRefresh) _postPage = 1;

    setState(() {
      _isLoadingPosts = true;
      _postError = null;
      if (isRefresh) {
        _favoritePosts = [];
        _postPaginationData = null;
      }
    });

    try {
      final currentUserId = widget.authProvider.currentUserId;
      if (currentUserId == null || currentUserId.isEmpty) {
        _resetDataForLoggedOutUser();
        return;
      }

      final PostListPagination postListResult =
          await widget.postService.getUserFavoritePostsPage(page: _postPage);

      if (!mounted) return;
      setState(() {
        if (isRefresh) {
          _favoritePosts = postListResult.posts;
        } else {
          _favoritePosts.addAll(postListResult.posts);
        }
        _postPaginationData = postListResult.pagination;
        _isLoadingPosts = false;
        _postError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPosts = false;
        _postError = '加载收藏帖子失败: ${e.toString().split(':').last.trim()}';
      });
      AppSnackBar.showError('加载收藏帖子失败');
    }
  }

  Future<void> _loadMorePosts() async {
    if (!mounted ||
        _isLoadingMorePosts ||
        !(_postPaginationData?.hasNextPage() ?? false)) {
      return;
    }

    _postPage++;
    setState(() {
      _isLoadingMorePosts = true;
    });

    try {
      final currentUserId = widget.authProvider.currentUserId;
      if (currentUserId == null || currentUserId.isEmpty) {
        _postPage--;
        _resetDataForLoggedOutUser();
        return;
      }

      final PostListPagination postListResult =
          await widget.postService.getUserFavoritePostsPage(page: _postPage);

      if (!mounted) return;
      setState(() {
        _favoritePosts.addAll(postListResult.posts);
        _postPaginationData = postListResult.pagination;
        _isLoadingMorePosts = false;
      });
    } catch (e) {
      if (!mounted) return;
      _postPage--;
      setState(() {
        _isLoadingMorePosts = false;
        _postError = '加载更多收藏帖子失败: ${e.toString().split(':').last.trim()}';
      });
      AppSnackBar.showError('加载更多收藏帖子失败');
    }
  }

  Future<void> _togglePostFavorite(String postId) async {
    try {
      await widget.postService.togglePostLike(postId);
      await _fetchPosts(isRefresh: true);
    } catch (e) {
      AppSnackBar.showError('取消收藏失败: ${e.toString()}');
    }
  }

  Future<void> _refreshCurrentFavorites() async {
    final currentTab = _tabController.index;
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }

    if (currentTab == 0) {
      await _fetchGames(isRefresh: true);
    } else {
      await _fetchPosts(isRefresh: true);
    }
  }

  Widget _buildFab() {
    return widget.authProvider.isLoggedIn
        ? GenericFloatingActionButton(
            icon: Icons.refresh,
            heroTag: "刷新收藏",
            onPressed: (_isLoadingGames ||
                    _isLoadingMoreGames ||
                    _isLoadingPosts ||
                    _isLoadingMorePosts)
                ? null
                : _refreshCurrentFavorites,
            tooltip: '刷新收藏',
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '我的喜欢',
      ),
      body: _buildBody(context),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream,
      initialData: widget.authProvider.currentUser,
      builder: (context, authSnapshot) {
        _currentUser = authSnapshot.data;
        final String? newUserId = _currentUser?.id;

        if (_prevUserId == null && newUserId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadFavoritesForTab(_tabController.index);
            }
          });
        }
        _prevUserId = newUserId;

        if (_currentUser == null) {
          return const LoginPromptWidget();
        }

        return _buildMainContent(context);
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingGames &&
        _gameError == null &&
        _favoriteGames.isEmpty &&
        _tabController.index == 0) {
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "等待加载...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }
    if (_isLoadingPosts &&
        _postError == null &&
        _favoritePosts.isEmpty &&
        _tabController.index == 1) {
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "少女正在祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }

    if (_gameError != null &&
        _gameError!.isNotEmpty &&
        _favoriteGames.isEmpty &&
        _tabController.index == 0) {
      return CustomErrorWidget(
          errorMessage: _gameError,
          onRetry: () => _fetchGames(isRefresh: true));
    }
    if (_postError != null &&
        _postError!.isNotEmpty &&
        _favoritePosts.isEmpty &&
        _tabController.index == 1) {
      return CustomErrorWidget(
        errorMessage: _postError,
        onRetry: () => _fetchPosts(isRefresh: true),
      );
    }

    return Column(
      children: [
        CustomSegmentedControlTabBar(
          controller: _tabController,
          tabTitles: _tabTitles,
          backgroundColor: theme.colorScheme.surface.withSafeOpacity(0.1),
          selectedTabColor: theme.primaryColor,
          unselectedTabColor: Colors.transparent,
          selectedTextStyle: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
          unselectedTextStyle: TextStyle(
            color: theme.textTheme.bodyLarge?.color?.withSafeOpacity(0.7) ??
                Colors.grey[700],
            fontWeight: FontWeight.normal,
          ),
          borderRadius: BorderRadius.circular(25.0),
          tabPadding: const EdgeInsets.symmetric(vertical: 12.0),
          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshCurrentFavorites,
            child: TabBarView(
              controller: _tabController,
              children: [
                GameLikesLayout(
                  favoriteGames: _favoriteGames,
                  paginationData: _gamePaginationData,
                  isLoadingInitial: _isLoadingGames && _favoriteGames.isEmpty,
                  isLoadingMore: _isLoadingMoreGames,
                  errorMessage: _gameError,
                  onRetryInitialLoad: () => _fetchGames(isRefresh: true),
                  onLoadMore: _loadMoreGames,
                  onToggleLike: _toggleGameLike,
                  scrollController: _gameScrollController,
                  windowStateProvider: widget.windowStateProvider,
                ),
                PostFavoritesLayout(
                  favoritePosts: _favoritePosts,
                  paginationData: _postPaginationData,
                  isLoadingInitial: _isLoadingPosts && _favoritePosts.isEmpty,
                  isLoadingMore: _isLoadingMorePosts,
                  errorMessage: _postError,
                  onRetryInitialLoad: () => _fetchPosts(isRefresh: true),
                  onLoadMore: _loadMorePosts,
                  onToggleFavorite: _togglePostFavorite,
                  scrollController: _postScrollController,
                  currentUser: _currentUser,
                  windowStateProvider: widget.windowStateProvider,
                  userInfoProvider: widget.infoProvider,
                  userFollowService: widget.followService,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

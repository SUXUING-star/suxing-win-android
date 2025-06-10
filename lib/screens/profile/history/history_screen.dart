// lib/screens/profile/history/history_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/models/game/game.dart'; // 导入游戏模型
import 'package:suxingchahui/models/post/post.dart'; // 导入帖子模型
import 'package:suxingchahui/models/common/pagination.dart'; // 导入分页模型
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/components/screen/history/game_history_layout.dart';
import 'package:suxingchahui/widgets/components/screen/history/post_history_layout.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackBar.dart';

class HistoryScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final GameService gameService;
  final PostService postService;
  final UserInfoProvider infoProvider;
  final UserFollowService followService;
  final WindowStateProvider windowStateProvider;
  const HistoryScreen({
    super.key,
    required this.gameService,
    required this.authProvider,
    required this.postService,
    required this.infoProvider,
    required this.followService,
    required this.windowStateProvider,
  });

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  // 游戏历史数据
  List<Game> _gameHistoryItems = [];
  PaginationData? _gameHistoryPagination;
  bool _isLoadingGameHistory = false;
  bool _isLoadingMoreGameHistory = false;
  String? _gameHistoryError;
  int _gameHistoryPage = 1;

  // 帖子历史数据
  List<Post> _postHistoryItems = [];
  PaginationData? _postHistoryPagination;
  bool _isLoadingPostHistory = false;
  bool _isLoadingMorePostHistory = false;
  String? _postHistoryError;
  int _postHistoryPage = 1;

  final ScrollController _gameScrollController = ScrollController();
  final ScrollController _postScrollController = ScrollController();

  User? _currentUser;
  String? _prevUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabChange);

    _gameScrollController
        .addListener(() => _handleScroll(_gameScrollController, 0));
    _postScrollController
        .addListener(() => _handleScroll(_postScrollController, 1));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _gameScrollController.dispose();
    _postScrollController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController!.indexIsChanging) {
      return;
    }
    // 每次切换标签页时，尝试加载对应数据，如果数据未加载过且用户已登录
    _loadHistoryForTab(_tabController!.index);
  }

  void _handleScroll(ScrollController controller, int tabIndex) {
    if (controller.position.pixels >=
        controller.position.maxScrollExtent * 0.9) {
      if (tabIndex == 0 &&
          !_isLoadingMoreGameHistory &&
          (_gameHistoryPagination?.hasNextPage() ?? false)) {
        _loadMoreGameHistory();
      } else if (tabIndex == 1 &&
          !_isLoadingMorePostHistory &&
          (_postHistoryPagination?.hasNextPage() ?? false)) {
        _loadMorePostHistory();
      }
    }
  }

  Future<void> _loadHistoryForTab(int tabIndex) async {
    final currentUserId = widget.authProvider.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      _resetDataForLoggedOutUser();
      return;
    }

    if (tabIndex == 0 && !_isLoadingGameHistory && _gameHistoryItems.isEmpty) {
      _fetchGameHistory(isRefresh: true);
    } else if (tabIndex == 1 &&
        !_isLoadingPostHistory &&
        _postHistoryItems.isEmpty) {
      _fetchPostHistory(isRefresh: true);
    }
  }

  void _resetDataForLoggedOutUser() {
    if (mounted) {
      setState(() {
        _gameHistoryItems = [];
        _gameHistoryPagination = null;
        _isLoadingGameHistory = false;
        _isLoadingMoreGameHistory = false;
        _gameHistoryError = null;
        _gameHistoryPage = 1;

        _postHistoryItems = [];
        _postHistoryPagination = null;
        _isLoadingPostHistory = false;
        _isLoadingMorePostHistory = false;
        _postHistoryError = null;
        _postHistoryPage = 1;
      });
    }
  }

  // --- 游戏历史相关方法 ---
  Future<void> _fetchGameHistory({bool isRefresh = false}) async {
    if (!mounted || (_isLoadingGameHistory && !isRefresh)) return;

    if (isRefresh) _gameHistoryPage = 1;

    setState(() {
      _isLoadingGameHistory = true;
      _gameHistoryError = null;
      if (isRefresh) {
        _gameHistoryItems = [];
        _gameHistoryPagination = null;
      }
    });

    try {
      final currentUserId = widget.authProvider.currentUserId;
      if (currentUserId == null || currentUserId.isEmpty) {
        _resetDataForLoggedOutUser();
        return;
      }

      final gameListResult = await widget.gameService
          .getGameHistoryWithDetails(_gameHistoryPage, 15);

      if (!mounted) return;
      setState(() {
        if (isRefresh) {
          _gameHistoryItems = gameListResult.games;
        } else {
          _gameHistoryItems.addAll(gameListResult.games);
        }
        _gameHistoryPagination = gameListResult.pagination;
        _isLoadingGameHistory = false;
        _gameHistoryError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingGameHistory = false;
        _gameHistoryError = '加载游戏历史失败: ${e.toString().split(':').last.trim()}';
      });
      AppSnackBar.showError( '加载游戏历史失败');
    }
  }

  Future<void> _loadMoreGameHistory() async {
    if (!mounted ||
        _isLoadingMoreGameHistory ||
        !(_gameHistoryPagination?.hasNextPage() ?? false)) {
      return;
    }

    _gameHistoryPage++;
    setState(() {
      _isLoadingMoreGameHistory = true;
    });

    try {
      final currentUserId = widget.authProvider.currentUserId;
      if (currentUserId == null || currentUserId.isEmpty) {
        _gameHistoryPage--;
        _resetDataForLoggedOutUser();
        return;
      }

      final gameListResult = await widget.gameService
          .getGameHistoryWithDetails(_gameHistoryPage, 15);

      if (!mounted) return;
      setState(() {
        _gameHistoryItems.addAll(gameListResult.games);
        _gameHistoryPagination = gameListResult.pagination;
        _isLoadingMoreGameHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      _gameHistoryPage--;
      setState(() {
        _isLoadingMoreGameHistory = false;
        _gameHistoryError =
            '加载更多游戏历史失败: ${e.toString().split(':').last.trim()}';
      });
      AppSnackBar.showError( '加载更多游戏历史失败');
    }
  }

  // --- 帖子历史相关方法 ---
  Future<void> _fetchPostHistory({bool isRefresh = false}) async {
    if (!mounted || (_isLoadingPostHistory && !isRefresh)) return;

    if (isRefresh) _postHistoryPage = 1;

    setState(() {
      _isLoadingPostHistory = true;
      _postHistoryError = null;
      if (isRefresh) {
        _postHistoryItems = [];
        _postHistoryPagination = null;
      }
    });

    try {
      final currentUserId = widget.authProvider.currentUserId;
      if (currentUserId == null || currentUserId.isEmpty) {
        _resetDataForLoggedOutUser();
        return;
      }

      final postListResult = await widget.postService
          .getPostHistoryWithDetails(_postHistoryPage, 10);

      if (!mounted) return;
      setState(() {
        if (isRefresh) {
          _postHistoryItems = postListResult.posts;
        } else {
          _postHistoryItems.addAll(postListResult.posts);
        }
        _postHistoryPagination = postListResult.pagination;
        _isLoadingPostHistory = false;
        _postHistoryError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPostHistory = false;
        _postHistoryError = '加载帖子历史失败: ${e.toString().split(':').last.trim()}';
      });
      AppSnackBar.showError('加载帖子历史失败');
    }
  }

  Future<void> _loadMorePostHistory() async {
    if (!mounted ||
        _isLoadingMorePostHistory ||
        !(_postHistoryPagination?.hasNextPage() ?? false)) {
      return;
    }

    _postHistoryPage++;
    setState(() {
      _isLoadingMorePostHistory = true;
    });

    try {
      final currentUserId = widget.authProvider.currentUserId;
      if (currentUserId == null || currentUserId.isEmpty) {
        _postHistoryPage--;
        _resetDataForLoggedOutUser();
        return;
      }

      final postListResult = await widget.postService
          .getPostHistoryWithDetails(_postHistoryPage, 10);

      if (!mounted) return;
      setState(() {
        _postHistoryItems.addAll(postListResult.posts);
        _postHistoryPagination = postListResult.pagination;
        _isLoadingMorePostHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      _postHistoryPage--;
      setState(() {
        _isLoadingMorePostHistory = false;
        _postHistoryError =
            '加载更多帖子历史失败: ${e.toString().split(':').last.trim()}';
      });
      AppSnackBar.showError('加载更多帖子历史失败');
    }
  }

  Future<void> _refreshCurrentHistory() async {
    final currentTab = _tabController!.index;
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }

    if (currentTab == 0) {
      await _fetchGameHistory(isRefresh: true);
    } else {
      await _fetchPostHistory(isRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '浏览历史'),
      body: StreamBuilder<User?>(
        stream: widget.authProvider.currentUserStream,
        initialData: widget.authProvider.currentUser,
        builder: (context, authSnapshot) {
          _currentUser = authSnapshot.data;
          final String? newUserId = _currentUser?.id;

          if (_prevUserId == null && newUserId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _loadHistoryForTab(_tabController?.index ?? 0);
              }
            });
          }
          _prevUserId = newUserId;

          if (_currentUser == null) {
            return const LoginPromptWidget();
          }

          return Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '游戏浏览历史'),
                  Tab(text: '帖子浏览历史'),
                ],
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshCurrentHistory,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      GameHistoryLayout(
                        gameHistoryItems: _gameHistoryItems,
                        paginationData: _gameHistoryPagination,
                        isLoadingInitial:
                            _isLoadingGameHistory && _gameHistoryItems.isEmpty,
                        isLoadingMore: _isLoadingMoreGameHistory,
                        onLoadMore: _loadMoreGameHistory,
                        onRetryInitialLoad: () =>
                            _fetchGameHistory(isRefresh: true),
                        errorMessage: _gameHistoryError,
                        scrollController: _gameScrollController,
                        windowStateProvider: widget.windowStateProvider,
                      ),
                      PostHistoryLayout(
                        postHistoryItems: _postHistoryItems,
                        paginationData: _postHistoryPagination,
                        isLoadingInitial:
                            _isLoadingPostHistory && _postHistoryItems.isEmpty,
                        isLoadingMore: _isLoadingMorePostHistory,
                        onLoadMore: _loadMorePostHistory,
                        onRetryInitialLoad: () =>
                            _fetchPostHistory(isRefresh: true),
                        errorMessage: _postHistoryError,
                        scrollController: _postScrollController,
                        currentUser: _currentUser,
                        userInfoProvider: widget.infoProvider,
                        windowStateProvider: widget.windowStateProvider,
                        userFollowService: widget.followService,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

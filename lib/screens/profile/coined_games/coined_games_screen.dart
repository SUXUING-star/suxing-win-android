// lib/screens/profile/coined_games/coined_games_screen.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_list_pagination.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/components/screen/coined_games/coined_games_layout.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart';

class CoinedGamesScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final GameService gameService;
  final WindowStateProvider windowStateProvider;

  const CoinedGamesScreen({
    super.key,
    required this.authProvider,
    required this.gameService,
    required this.windowStateProvider,
  });

  @override
  _CoinedGamesScreenState createState() => _CoinedGamesScreenState();
}

class _CoinedGamesScreenState extends State<CoinedGamesScreen> {
  List<Game> _coinedGames = [];
  PaginationData? _gamePaginationData;
  bool _isLoadingGames = false; // 初始为 false，由 StreamBuilder 触发加载
  bool _isLoadingMoreGames = false;
  String? _gameError;
  int _gamePage = 1;

  final ScrollController _scrollController = ScrollController();

  // 用于跟踪用户ID变化，避免重复加载
  User? _currentUser;
  String? _prevUserId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMoreGames &&
          (_gamePaginationData?.hasNextPage() ?? false)) {
        _loadMoreGames();
      }
    }
  }

  void _resetDataForLoggedOutUser() {
    if (mounted) {
      setState(() {
        _coinedGames = [];
        _gamePaginationData = null;
        _isLoadingGames = false;
        _isLoadingMoreGames = false;
        _gameError = null;
        _gamePage = 1;
      });
    }
  }

  Future<void> _fetchGames({bool isRefresh = false}) async {
    // 检查登录状态，未登录则直接重置数据
    final currentUserId = widget.authProvider.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      _resetDataForLoggedOutUser();
      return;
    }

    if (!mounted || (_isLoadingGames && !isRefresh)) return;

    if (isRefresh) _gamePage = 1;

    setState(() {
      _isLoadingGames = true;
      _gameError = null;
      if (isRefresh) {
        _coinedGames = [];
        _gamePaginationData = null;
      }
    });

    try {
      final GameListPagination gameListResult =
          await widget.gameService.getUserCoinedGames(page: _gamePage);

      if (!mounted) return;
      setState(() {
        if (isRefresh) {
          _coinedGames = gameListResult.games;
        } else {
          _coinedGames.addAll(gameListResult.games);
        }
        _gamePaginationData = gameListResult.pagination;
        _isLoadingGames = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingGames = false;
        _gameError = '加载投币游戏失败: ${e.toString().split(':').last.trim()}';
      });
      AppSnackBar.showError('加载投币游戏失败');
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
      final GameListPagination gameListResult =
          await widget.gameService.getUserCoinedGames(page: _gamePage);

      if (!mounted) return;
      setState(() {
        _coinedGames.addAll(gameListResult.games);
        _gamePaginationData = gameListResult.pagination;
        _isLoadingMoreGames = false;
      });
    } catch (e) {
      if (!mounted) return;
      _gamePage--;
      setState(() {
        _isLoadingMoreGames = false;
      });
      AppSnackBar.showError('加载更多投币游戏失败');
    }
  }

  Future<void> _refresh() async {
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        AppSnackBar.showLoginRequiredSnackBar(context);
      }
      return;
    }
    await _fetchGames(isRefresh: true);
  }

  Widget _buildFab() {
    return widget.authProvider.isLoggedIn
        ? GenericFloatingActionButton(
            icon: Icons.refresh,
            heroTag: "刷新投币记录",
            onPressed:
                (_isLoadingGames || _isLoadingMoreGames) ? null : _refresh,
            tooltip: '刷新',
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '我的投币',
      ),
      body: _buildBody(context),
      floatingActionButton: _buildFab(),
    );
  }

  // 核心逻辑转移到这里，完全照抄 FavoritesScreen 的模式
  Widget _buildBody(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream,
      initialData: widget.authProvider.currentUser,
      builder: (context, authSnapshot) {
        _currentUser = authSnapshot.data;
        final String? newUserId = _currentUser?.id;

        // 当用户从“未登录”变为“已登录”时，触发一次加载
        if (_prevUserId == null && newUserId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _coinedGames.isEmpty) {
              // 避免重复加载
              _fetchGames(isRefresh: true);
            }
          });
        }
        // 当用户登出时，清空数据
        else if (_prevUserId != null && newUserId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _resetDataForLoggedOutUser();
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

  // 构建主内容区域
  Widget _buildMainContent(BuildContext context) {
    // 初始加载时，显示加载动画
    if (_isLoadingGames && _coinedGames.isEmpty) {
      return const FadeInItem(
        child: LoadingWidget(
          isOverlay: true,
          message: "正在查询投币记录...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      );
    }

    // 初始加载失败时，显示错误页面
    if (_gameError != null && _coinedGames.isEmpty) {
      return CustomErrorWidget(
        errorMessage: _gameError,
        onRetry: () => _fetchGames(isRefresh: true),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CoinedGamesLayout(
        coinedGames: _coinedGames,
        paginationData: _gamePaginationData,
        isLoadingInitial: _isLoadingGames && _coinedGames.isEmpty,
        isLoadingMore: _isLoadingMoreGames,
        errorMessage: _gameError,
        onRetryInitialLoad: () => _fetchGames(isRefresh: true),
        onLoadMore: _loadMoreGames,
        scrollController: _scrollController,
        windowStateProvider: widget.windowStateProvider,
      ),
    );
  }
}

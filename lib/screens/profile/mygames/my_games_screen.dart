// lib/screens/profile/mygames/my_games_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game/game_list_pagination.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/screen/mygames/my_games_layout.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';
import 'package:suxingchahui/models/game/game/game.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';

class MyGamesScreen extends StatefulWidget {
  final GameService gameService;
  final AuthProvider authProvider;
  final WindowStateProvider windowStateProvider;
  const MyGamesScreen({
    super.key,
    required this.gameService,
    required this.authProvider,
    required this.windowStateProvider,
  });

  @override
  _MyGamesScreenState createState() => _MyGamesScreenState();
}

class _MyGamesScreenState extends State<MyGamesScreen> {
  final ScrollController _scrollController = ScrollController();

  List<Game> _myGames = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasInitializedDependencies = false;

  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;

  static const Duration _minRefreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
      _loadGames();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载游戏
  ///
  Future<void> _loadGames({
    bool forceRefresh = false, // 这个是手动刷新
    int pageToFetch = 1,
  }) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _currentPage = 1;
      _myGames.clear();
      _errorMessage = '';
    });

    try {
      if (!widget.authProvider.isLoggedIn) {
        setState(() {
          _isLoading = false;
          _hasError = false;
          _myGames.clear();
          _errorMessage = '';
        });
        return;
      }

      final GameListPagination result =
          await widget.gameService.getMyGamesWithInfo(
        page: pageToFetch,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _myGames = result.games;
        _totalPages = result.pagination.pages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '加载我的游戏列表失败: ${e.toString().split(':').last.trim()}';
      });
      AppSnackBar.showError('加载失败，请稍后重试');
    }
  }

  /// 手动刷新
  ///
  Future<void> _refreshGames({
    bool needCheck = true,
  }) async {
    if (!mounted || _isRefreshing) return;

    final now = DateTime.now();

    if (needCheck) {
      // 需要进行时间间隔检查时
      if (_lastRefreshTime != null &&
          now.difference(_lastRefreshTime!) < _minRefreshInterval) {
        // 时间间隔不足时
        if (mounted) {
          AppSnackBar.showWarning(
              '刷新太频繁啦，请 ${(_minRefreshInterval.inSeconds - now.difference(_lastRefreshTime!).inSeconds)} 秒后再试'); // 提示刷新频繁
        }
        return; // 返回
      }
    }

    setState(() {
      _isRefreshing = true;
      _lastRefreshTime = now;
    });
    try {
      await _loadGames(
        forceRefresh: true,
        pageToFetch: _currentPage,
      );
      setState(() {
        _isRefreshing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// 加载更多
  ///
  Future<void> _loadMoreGames() async {
    if (!widget.authProvider.isLoggedIn) return;
    if (_isFetchingMore ||
        _currentPage >= _totalPages ||
        _isLoading ||
        _hasError) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await widget.gameService.getMyGamesWithInfo(
        page: nextPage,
      );

      if (!mounted) return;

      setState(() {
        _myGames.addAll(result.games);
        _currentPage = nextPage;
        _totalPages = result.pagination.pages;
        _isFetchingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFetchingMore = false;
      });
      AppSnackBar.showWarning('加载更多失败');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreGames();
    }
  }

  void _showReviewCommentDialog(String comment) {
    CustomInfoDialog.show(
      context: context,
      title: '拒绝原因',
      message: comment,
      iconData: Icons.comment_outlined,
      iconColor: Colors.orange,
      closeButtonText: '知道了',
    );
  }

  /// 添加游戏
  ///
  void _handleAddGame() {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    NavigationUtils.pushNamed(context, AppRoutes.addGame).then((result) {
      if (result == true && mounted) {
        _loadGames(pageToFetch: 1, forceRefresh: true); // 添加不知道是哪页
      }
    });
  }

  Future<void> _handleEditOrResubmit(Game game) async {
    if (!mounted) return;
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    // 直接跳转到 EditGameScreen，并把游戏ID传过去。
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.editGame,
      arguments: game.id, // 把 gameId 作为参数传递
    );

    // 从编辑页面返回后，如果返回了 true，说明有变更，需要刷新列表。
    if (result == true && mounted) {
      // 为了最快看到反馈，不检查刷新间隔。
      await _loadGames(
          pageToFetch: _currentPage, forceRefresh: true); // 编辑肯定是当前页码
    }
  }

  String _makeHeroTag(
      {required bool isDesktopLayout, required String mainCtx}) {
    final ctxDevice = isDesktopLayout ? 'desktop' : 'mobile';
    const ctxScreen = 'my_games';
    return '${ctxScreen}_${ctxDevice}_${mainCtx}_${widget.authProvider.currentUserId}';
  }

  Widget _buildFab(bool isDesktopLayout) {
    return FloatingActionButtonGroup(
      toggleButtonHeroTag: 'my_games_heroTags',
      children: [
        GenericFloatingActionButton(
          onPressed: _handleAddGame,
          icon: Icons.add,
          tooltip: '提交新游戏',
          heroTag:
              _makeHeroTag(isDesktopLayout: isDesktopLayout, mainCtx: 'add'),
        ),
        GenericFloatingActionButton(
          isLoading: _isRefreshing,
          onPressed: () => _refreshGames(needCheck: true),
          icon: Icons.refresh_rounded,
          tooltip: '刷新',
          heroTag: _makeHeroTag(
              isDesktopLayout: isDesktopLayout, mainCtx: 'refresh'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktopLayout = DeviceUtils.isDesktopInThisWidth(screenWidth);
        return Scaffold(
          appBar: const CustomAppBar(title: '我的游戏'),
          body: StreamBuilder<User?>(
            stream: widget.authProvider.currentUserStream,
            initialData: widget.authProvider.currentUser,
            builder: (context, authSnapshot) {
              final currentUser = authSnapshot.data;

              if (currentUser == null) {
                return const LoginPromptWidget();
              }

              if (_isLoading && _myGames.isEmpty && !_hasError) {
                return const FadeInItem(
                  // 全屏加载组件
                  child: LoadingWidget(
                    isOverlay: true,
                    message: "少女祈祷中...",
                    overlayOpacity: 0.4,
                    size: 36,
                  ),
                ); //
              }

              if (_hasError && _myGames.isEmpty) {
                return CustomErrorWidget(
                  onRetry: () => _loadGames(forceRefresh: true),
                  errorMessage:
                      _errorMessage.isNotEmpty ? _errorMessage : '加载失败，请点击重试',
                );
              }

              return RefreshIndicator(
                onRefresh: () => _refreshGames(needCheck: true),
                child: MyGamesLayout(
                  myGames: _myGames,
                  screenWidth: screenWidth,
                  isDesktopLayout: isDesktopLayout,
                  isLoadingMore: _isFetchingMore,
                  hasMore: _currentPage < _totalPages,
                  scrollController: _scrollController,
                  onLoadMore: _loadMoreGames,
                  onAddGame: _handleAddGame,
                  onEdit: _handleEditOrResubmit,
                  onShowReviewComment: _showReviewCommentDialog,
                  authProvider: widget.authProvider,
                ),
              );
            },
          ),
          floatingActionButton: widget.authProvider.isLoggedIn
              ? _buildFab(isDesktopLayout)
              : null,
        );
      },
    );
  }
}

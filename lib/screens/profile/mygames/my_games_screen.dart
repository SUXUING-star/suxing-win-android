// lib/screens/profile/mygames/my_games_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game_list_pagination.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/screen/mygames/my_games_layout.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snackBar.dart';
import 'package:suxingchahui/models/game/game.dart';
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
      _loadInitialGames();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialGames() async {
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
        page: 1,
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

  Future<void> _handleResubmit(Game game) async {
    if (!mounted) return;
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (game.authorId != widget.authProvider.currentUserId) {
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }
    await CustomConfirmDialog.show(
      context: context,
      title: '确认重新提交？',
      message: '您确定要将《${game.title}》重新提交审核吗？',
      confirmButtonText: '重新提交',
      confirmButtonColor: Colors.blue,
      iconData: Icons.help_outline,
      iconColor: Colors.blue,
      onConfirm: () async {
        await _executeResubmit(game);
      },
    );
  }

  Future<void> _executeResubmit(Game game) async {
    if (game.approvalStatus != GameStatus.rejected) return;

    try {
      await widget.gameService.resubmitGame(game);
      if (!mounted) return;

      AppSnackBar.showSuccess('《${game.title}》已重新提交审核');
      await _loadInitialGames();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError('重新提交失败: ${e.toString()}');
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

  void _handleAddGame() {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    NavigationUtils.pushNamed(context, AppRoutes.addGame).then((result) {
      if (result == true && mounted) {
        _loadInitialGames();
      }
    });
  }

  Widget _buildFab() {
    return GenericFloatingActionButton(
      onPressed: _handleAddGame,
      icon: Icons.add,
      tooltip: '提交新游戏',
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onRetry: _loadInitialGames,
              errorMessage:
                  _errorMessage.isNotEmpty ? _errorMessage : '加载失败，请点击重试',
            );
          }

          return RefreshIndicator(
            onRefresh: _loadInitialGames,
            child: LazyLayoutBuilder(
              windowStateProvider: widget.windowStateProvider,
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isDesktopLayout =
                    DeviceUtils.isDesktopInThisWidth(screenWidth);
                return MyGamesLayout(
                  myGames: _myGames,
                  screenWidth: screenWidth,
                  isDesktopLayout: isDesktopLayout,
                  isLoadingMore: _isFetchingMore,
                  hasMore: _currentPage < _totalPages,
                  scrollController: _scrollController,
                  onLoadMore: _loadMoreGames,
                  onAddGame: _handleAddGame,
                  onResubmit: _handleResubmit,
                  onShowReviewComment: _showReviewCommentDialog,
                  authProvider: widget.authProvider,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: widget.authProvider.isLoggedIn ? _buildFab() : null,
    );
  }
}

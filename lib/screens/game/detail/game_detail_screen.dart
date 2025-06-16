// lib/screens/game/detail/game_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game_detail_param.dart';
import 'package:suxingchahui/models/game/game_navigation_info.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/error/api_error_definitions.dart';
import 'package:suxingchahui/services/error/api_exception.dart';
import 'package:suxingchahui/services/main/game/game_collection_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart';
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_sliver_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/widgets/components/screen/game/game_detail_layout.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class GameDetailScreen extends StatefulWidget {
  final GameDetailParam? gameDetailParam;
  final bool isNeedHistory;
  final GameCollectionService gameCollectionService;
  final AuthProvider authProvider;
  final GameService gameService;
  final UserInfoProvider infoProvider;
  final UserFollowService followService;
  final InputStateService inputStateService;
  final GameListFilterProvider gameListFilterProvider;
  final SidebarProvider sidebarProvider;
  final WindowStateProvider windowStateProvider;
  const GameDetailScreen({
    super.key,
    this.gameDetailParam,
    this.isNeedHistory = true,
    required this.authProvider,
    required this.gameCollectionService,
    required this.infoProvider,
    required this.inputStateService,
    required this.gameService,
    required this.gameListFilterProvider,
    required this.followService,
    required this.sidebarProvider,
    required this.windowStateProvider,
  });
  @override
  _GameDetailScreenState createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late String? _currentUserId;

  late final String _gameId;
  Game? _game;
  GameCollectionItem? _collectionStatus;
  GameNavigationInfo? _navigationInfo;
  bool? _isLiked; // 持有喜欢状态
  bool? _isCoined; // 持有投币状态
  int _likeCount = 0;
  int _coinsCount = 0;
  String? _error;
  bool _isLoading = false;
  bool _isTogglingLike = false; // 用于跟踪点赞操作的处理状态
  bool _isTogglingCoin = false; // 用于跟踪投币操作的处理状态
  int _refreshCounter = 0;
  bool _hasInitializedDependencies = false;
  bool _isPageScrollLocked = false; // 代表页面是否被锁定滚动

  bool _isPerformingGamesDetailRefresh = false;
  DateTime? _lastGamesDetailRefreshAttemptTime;
  static const Duration _minRefreshGameDetailInterval = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    final p = widget.gameDetailParam;
    final g = widget.gameDetailParam?.gameId;
    if (p == null || g == null) {
      setState(() {
        _error = '无效的游戏ID';
        _isLoading = false;
      });
    } else {
      _gameId = g;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _currentUserId = widget.authProvider.currentUserId;
      _hasInitializedDependencies = true;
    }

    if (_error != null && _hasInitializedDependencies) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = true;
        _lastGamesDetailRefreshAttemptTime = DateTime.now();
        // 第一次初始化赋值，之后走下面的流程
        _loadGameDetailsWithStatus(); // 原有的调用
      });
    }
  }

  @override
  void didUpdateWidget(GameDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool didUpdate = false;

    if (oldWidget.gameDetailParam?.gameId != widget.gameDetailParam?.gameId) {
      didUpdate = true;
    }
    if (widget.authProvider.currentUserId != _currentUserId) {
      didUpdate = true;
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId;
        });
      }
    }
    if (didUpdate) {
      // 这是回调更新，第二次构建的情况
      setState(() {
        _game = null;
        _collectionStatus = null;
        _navigationInfo = null;
        _isLiked = null;
        _isCoined = null;
        _error = null;
        _isLoading = true;
        _isTogglingLike = false;
        _refreshCounter = 0; // 可以重置
      });
      _loadGameDetailsWithStatus();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _currentUserId = null;
    _game = null;
    _error = null;
    _isLiked = null;
    _isCoined = null;
  }

  // --- 尝试增加游戏浏览次数 ---
  Future<void> _tryIncrementViewCount() async {
    // 检查游戏数据已加载、游戏ID有效、游戏状态为'approved'、且需要记录历史
    if (_game != null &&
        _game!.approvalStatus == GameStatus.approved &&
        widget.isNeedHistory) {
      try {
        widget.gameService.incrementGameView(_gameId);
      } catch (e) {
        // 啥也不做
      }

      // 不要等待，异步进行
    }
  }

  // 加载游戏详情和收藏状态
  Future<void> _loadGameDetailsWithStatus({bool forceRefresh = false}) async {
    if (!mounted) return;

    if (!_isLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    GameDetailsWithStatus? result;
    String? errorMsg; // 用于 finally 块判断
    bool gameWasRemoved = false; // 新增标志位

    try {
      result = await widget.gameService.getGameDetailsWithStatus(_gameId);
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException) {
        // 直接用后端返回的、定义好的错误码
        errorMsg = e.apiErrorCode;

        // 判断是不是"未找到"
        if (e.apiErrorCode == BackendApiErrorCodes.notFound) {
          gameWasRemoved = true; // 标记游戏已被移除

          // *** 显示补偿/移除对话框 ***
          // 使用 addPostFrameCallback 确保在当前帧渲染完成后执行
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // 再次检查 mounted 状态
              CustomInfoDialog.show(
                context: context,
                title: '游戏已移除',
                message: '抱歉，您尝试访问的游戏已被移除或不存在。',
                iconData: Icons.delete_forever_outlined,
                // 或者 Icons.sentiment_very_dissatisfied
                iconColor: Colors.redAccent,
                closeButtonText: '知道了',
                barrierDismissible: false,
                // 不允许点击外部关闭，强制用户确认
                onClose: () {
                  // 用户点击“知道了”之后的操作
                  if (mounted) {
                    // 安全地执行 Pop 操作
                    // 使用 try-catch 增加健壮性，防止 pop 时 context 无效
                    try {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        NavigationUtils.navigateToHome(
                            widget.sidebarProvider, context);
                      }
                    } catch (popError) {
                      // 备用方案：导航到主页
                      NavigationUtils.navigateToHome(
                          widget.sidebarProvider, context);
                    }
                  }
                },
              );
            }
          });
        }
        // 处理其他已知错误
      } else {
        errorMsg = '加载失败: ${e.toString()}';
      }
    } finally {
      // *** 只有在游戏未被移除时才更新状态 ***
      if (mounted && !gameWasRemoved) {
        setState(() {
          if (errorMsg == null && result != null) {
            // 成功
            _game = result.game;
            _collectionStatus = result.collectionStatus;
            _navigationInfo = result.navigationInfo;
            _isLiked = result.isLiked;
            _isCoined = result.isCoined;
            _likeCount = result.game.likeCount;
            _coinsCount = result.game.coinsCount;
            _error = null;
          } else {
            // 加载/刷新失败，但游戏 *并未* 被移除
            if (_game == null) {
              // 首次失败
              _error = errorMsg ?? '未知错误';
              _isLiked = null;
              _isCoined = null;
            } else {
              // 刷新失败
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AppSnackBar.showError("刷新失败: ${errorMsg ?? '未知错误'}");
              });
              // 保留旧数据，只显示 Toaster
            }
          }
          _isLoading = false;
          _isTogglingLike = false;
          _isTogglingCoin = false;
          _refreshCounter++;
        });
        await _tryIncrementViewCount();
      } else if (mounted && gameWasRemoved) {
        // 如果游戏被移除，我们不应该更新 _game 等状态
        // 只需确保 loading 状态结束
        setState(() {
          _isLoading = false;
          _isTogglingLike = false;
          _isTogglingCoin = false;
        });
      }
    }
  }

  // 刷新逻辑
  Future<void> _refreshGameDetails({bool needCheck = false}) async {
    if (!mounted) return;

    if (_isPerformingGamesDetailRefresh) {
      return;
    }
    _isPerformingGamesDetailRefresh = true;
    final now = DateTime.now();

    if (needCheck) {
      if (_lastGamesDetailRefreshAttemptTime != null &&
          now.difference(_lastGamesDetailRefreshAttemptTime!) <
              _minRefreshGameDetailInterval) {
        final remainSeconds = _minRefreshGameDetailInterval.inSeconds -
            now.difference(_lastGamesDetailRefreshAttemptTime!).inSeconds;

        AppSnackBar.showInfo("手速太快，请等待 $remainSeconds 秒后再尝试");
      }
      _lastGamesDetailRefreshAttemptTime = now;
    } else {
      _lastGamesDetailRefreshAttemptTime = now;
    }

    try {
      // 调用加载，forceRefresh 确保即使短时间内连续操作也会尝试重新加载
      await _loadGameDetailsWithStatus(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      _isPerformingGamesDetailRefresh = false;
    }
  }

  Future<void> _handleCollectionStateChangedInButton(
    GameCollectionItem? newCollectionStatus,
    Game? updatedGame,
  ) async {
    // 1. 安全检查
    if (!mounted) {
      return;
    }

    // 2. 直接用后端返回的数据更新状态，一把梭！
    //    如果后端因为某些原因没返回 updatedGame，我们就不更新 _game，保持现状
    //    这样可以防止界面数据错乱
    if (updatedGame != null) {
      setState(() {
        _collectionStatus = newCollectionStatus; // 更新收藏状态
        _game = updatedGame; // 直接替换成后端爹给的最新 game 对象
        _refreshCounter++; // 强制子组件重建，显示最新数据
      });
    } else {
      // 如果 updatedGame 是 null，只更新 collectionStatus，游戏数据等下次刷新
      // 这是一种防御性编程
      setState(() {
        _collectionStatus = newCollectionStatus;
        _refreshCounter++;
      });
    }
  }

  // 处理投币切换的回调函数
  Future<void> _handleToggleCoin() async {
    if (_isTogglingCoin || !mounted || _game == null) {
      return;
    }

    if (!widget.authProvider.isLoggedIn) {
      // 未登录时，不显示对话框，直接提示登录
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    final currentUser = widget.authProvider.currentUser;
    if (currentUser == null) {
      AppSnackBar.showError("无法获取用户信息，请稍后重试");
      return;
    }

    final int userCoinCount = currentUser.coins;
    final bool isAuthor = _game!.authorId == currentUser.id; // 判断当前用户是否为游戏作者

    if (mounted) {
      setState(() {
        _isTogglingCoin = true; // 用于对话框关闭后UI状态的同步
      });
    }

    String dialogTitle;
    Widget contentDetail;
    String confirmButtonText;
    bool showCancelButton;
    bool canPerformCoinAction = false; // 标记是否能真正执行投币API

    if (isAuthor) {
      // 当前用户是作者
      dialogTitle = '操作提示';
      contentDetail = const AppText(
        '您是该游戏的作者，不能给自己投币哦！',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.black54),
      );
      confirmButtonText = '知道了';
      showCancelButton = false;
    } else if (_isCoined == true) {
      // 当前用户已投币
      dialogTitle = '操作提示';
      contentDetail = const AppText(
        '您已经为这个游戏投过币啦！',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.black54),
      );
      confirmButtonText = '知道了';
      showCancelButton = false;
    } else if (userCoinCount <= 0) {
      // 用户硬币不足
      dialogTitle = '硬币不足';
      contentDetail = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.black54),
              children: [
                const TextSpan(text: '您当前的硬币数量为: '),
                TextSpan(
                  text: '$userCoinCount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.red.shade600,
                  ),
                ),
                const TextSpan(text: ' 枚'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const AppText(
            '快去签到获取更多硬币吧！',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
        ],
      );
      confirmButtonText = '知道了';
      showCancelButton = false;
    } else {
      // 用户可以进行投币
      dialogTitle = '确认投币';
      contentDetail = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.black54),
              children: [
                const TextSpan(text: '您当前的硬币数量为: '),
                TextSpan(
                  text: '$userCoinCount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green.shade600,
                  ),
                ),
                const TextSpan(text: ' 枚'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const AppText(
            '投币将消耗 1 枚硬币，此操作无法撤销。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
        ],
      );
      confirmButtonText = '投币';
      showCancelButton = true;
      canPerformCoinAction = true; // 允许执行投币API调用
    }

    await BaseInputDialog.show<void>(
      context: context,
      title: dialogTitle,
      iconData: Icons.monetization_on,
      iconColor: Colors.orange.shade700,
      showCancelButton: showCancelButton,
      confirmButtonText: confirmButtonText,
      contentBuilder: (dialogContext) {
        return contentDetail;
      },
      onConfirm: () async {
        if (!canPerformCoinAction) {
          // 如果标记为不能执行投币，则确认按钮仅关闭对话框
          return;
        }

        try {
          final (coinSpent, updatedGame) =
              await widget.gameService.coinGame(game: _game!); // 调用后端API执行投币

          await _loadGameDetailsWithStatus();
          if (mounted) {
            setState(() {
              _isCoined = true; // 更新UI状态为已投币
              _coinsCount = _coinsCount + coinSpent;
            });
          }
          AppSnackBar.showSuccess('投币成功！');
        } catch (e) {
          if (mounted) {
            AppSnackBar.showError(e.toString());
          }
          rethrow; // 重新抛出异常，以便BaseInputDialog可以处理
        }
      },
    );

    if (mounted) {
      setState(() {
        _isTogglingCoin = false; // 结束处理状态
      });
    }
  }

  // 处理点赞切换的回调函数
  Future<void> _handleToggleLike() async {
    // 保持前置检查
    if (_isTogglingLike || !mounted) return;

    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    setState(() {
      _isTogglingLike = true; // 开始按钮 loading
    });

    try {
      // 调用返回 Future<bool> 的 service 方法
      final (newIsLikedStatus, updatedGame) =
          await widget.gameService.toggleLike(
        gameId: _gameId,
        oldStatus: _isLiked,
      );

      if (mounted) {
        setState(() {
          _isLiked = newIsLikedStatus; // 直接更新点赞状态
          _likeCount = newIsLikedStatus ? _likeCount++ : _likeCount--;
        });

        AppSnackBar.showSuccess(newIsLikedStatus ? '点赞成功' : '已取消点赞');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingLike = false; // 结束 loading
        });
      }
    }
  }

  // 处理游戏导航的回调
  void _handleNavigate(String gameId) {
    NavigationUtils.pushNamed(context, AppRoutes.gameDetail, arguments: gameId);
  }

  // 检查当前用户是否有权限编辑游戏
  bool _canEditOrDeleteGame(Game game) {
    final canEdit = widget.authProvider.isAdmin
        ? true
        : widget.authProvider.currentUserId == game.authorId;
    return canEdit;
  }

  // 处理编辑按钮点击事件
  void _handleEditPressed(Game game) async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
    }
    if (!_canEditOrDeleteGame(game)) {
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }
    final result = await NavigationUtils.pushNamed(context, AppRoutes.editGame,
        arguments: game.id);
    if (result == true && mounted) {
      _refreshGameDetails(needCheck: false); // 强制刷新
    }
  }

  /// Handles delete action (using your original onConfirm logic).
  Future<void> _handleDeletePressed(Game game) async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_canEditOrDeleteGame(game)) {
      AppSnackBar.showPermissionDenySnackBar();
      return;
    }
    await CustomConfirmDialog.show(
      context: context,
      title: '确认删除',
      message: '确定要删除这个游戏吗？此操作无法撤销。',
      confirmButtonText: '删除',
      confirmButtonColor: Colors.red,
      iconData: Icons.delete_forever,
      iconColor: Colors.red,
      onConfirm: () async {
        // onConfirm 是 AsyncCallback?
        try {
          await widget.gameService.deleteGame(game);
          // 刷新由 cache watcher 触发
          if (!mounted) return;
          AppSnackBar.showGameDeleteSuccessfullySnackBar();
        } catch (e) {
          AppSnackBar.showError("删除游戏失败,${e.toString()}");
          // print("删除游戏失败: $gameId, Error: $e");
        }
      },
    );
  }

  // --- UI 构建方法 ---

  Widget _buildPendingApprovalBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.orange.shade700,
      width: double.infinity,
      child: const SafeArea(
        // Use SafeArea for status bar overlap avoidance
        bottom: false,
        child: Text(
          '提示：此游戏正在审核中，内容未公开可见。',
          style: TextStyle(color: Colors.white, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildActionButtonsGroup(
    BuildContext context,
    Game game,
    bool isDesktop,
  ) {
    final String editHeroTag =
        isDesktop ? 'editButtonDesktop' : 'editButtonMobile';
    final String deleteHeroTag =
        isDesktop ? 'deleteButtonDesktop' : 'deleteButtonMobile';
    final String likeHeroTag = isDesktop
        ? 'likeButtonDesktop'
        : 'likeButtonMobile'; // 给点赞按钮也加上区分的 heroTag

    final String coinHeroTag =
        isDesktop ? 'coinButtonDesktop' : 'coinButtonMobile';

    const String refreshHeroTag = 'gameDetailRefresh';

    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color greyColor = Colors.grey.shade600; // 用于未点赞状态的颜色（可选）

    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream,
      initialData: widget.authProvider.currentUser,
      builder: (context, currentUserSnapshot) {
        final User? currentUser = currentUserSnapshot.data;
        if (currentUser == null) return const SizedBox.shrink();
        final bool isAdmin = currentUser.isAdmin;
        final bool isAuthor = game.authorId == currentUser.id;
        final bool canEdit = isAdmin ? true : currentUser.id == game.authorId;
        return Padding(
          // 给整个按钮组添加统一的外边距
          padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          child: FloatingActionButtonGroup(
            toggleButtonHeroTag: "game_detail_heroTags",
            spacing: 16.0, // 按钮间距
            alignment: MainAxisAlignment.end, // 底部对齐
            children: [
              GenericFloatingActionButton(
                onPressed: () => _refreshGameDetails(),
                isLoading: _isPerformingGamesDetailRefresh,
                icon: Icons.refresh,
                tooltip: "刷新",
                mini: true,
                heroTag: refreshHeroTag,
              ),
              // --- 第一个按钮：点赞按钮或占位符 ---
              if (_isLiked != null) // 确保状态已加载
                GenericFloatingActionButton(
                  key: ValueKey('like_fab_$_gameId'),
                  // 使用 FAB 特定的 Key
                  heroTag: likeHeroTag,
                  backgroundColor: Colors.white,
                  tooltip: _isLiked! ? '取消点赞' : '点赞',
                  // 根据状态显示不同提示
                  icon: _isLiked! ? Icons.favorite : Icons.favorite_border,
                  // 根据状态切换图标
                  mini: true,
                  foregroundColor: _isLiked! ? primaryColor : greyColor,
                  onPressed: _handleToggleLike,
                  isLoading: _isTogglingLike, // 把加载状态传递给通用 FAB
                )
              else
                // 加载占位符 (保持不变)
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: LoadingWidget(),
                ),

              // --- 新增：投币按钮或占位符 ---
              if (_isCoined != null)
                GenericFloatingActionButton(
                  key: ValueKey('coin_fab_$_gameId'),
                  heroTag: coinHeroTag,
                  backgroundColor: Colors.white,
                  tooltip: (_isCoined! || isAuthor)
                      ? (isAuthor ? '作者不能投币' : '已投币')
                      : '投币',
                  icon: Icons.monetization_on, // 投币图标
                  mini: true,
                  // 如果已投币改变颜色
                  foregroundColor: (_isCoined! || isAuthor)
                      ? Colors.orange.shade700
                      : greyColor,
                  onPressed: _isCoined! ? null : _handleToggleCoin,
                  isLoading: _isTogglingCoin,
                )
              else
                // 加载占位符
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: LoadingWidget(),
                ),

              if (canEdit)
                GenericFloatingActionButton(
                  heroTag: editHeroTag,
                  // 使用区分后的 heroTag
                  mini: true,
                  // 统一使用 mini 尺寸，或根据需要调整
                  tooltip: '编辑',
                  icon: Icons.edit,
                  onPressed: () => _handleEditPressed(game),
                  backgroundColor: Colors.white,
                  // 白色背景
                  foregroundColor: Theme.of(context).primaryColor, // 主题色图标
                ),
              if (canEdit)
                GenericFloatingActionButton(
                  heroTag: deleteHeroTag,
                  // 使用区分后的 heroTag
                  mini: true,
                  // 统一使用 mini 尺寸，或根据需要调整
                  tooltip: '删除',
                  icon: Icons.delete_forever,
                  onPressed: () => _handleDeletePressed(game),
                  backgroundColor: Colors.white,
                  // 白色背景
                  foregroundColor: Theme.of(context).primaryColor, // 主题色图标
                ),
            ],
          ),
        );
      },
    );
  }

  // Mobile Layout 构建
  Widget _buildMobileLayout(Game game, bool isPending, bool isDesktop) {
    final flexibleSpaceBackground = Stack(
      fit: StackFit.expand,
      children: [
        SafeCachedImage(
          imageUrl: game.coverImage,
          fit: BoxFit.cover,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.5, 1.0],
              colors: [
                Colors.transparent,
                Colors.black87,
              ],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: [0.8, 1.0],
              colors: [
                Colors.transparent,
                Colors.black38,
              ],
            ),
          ),
        ),
      ],
    );
    final ScrollController mobileScrollController = ScrollController();

    return Scaffold(
      body: Scrollbar(
        interactive: false,
        controller: mobileScrollController,
        thumbVisibility: true,
        child: RefreshIndicator(
          onRefresh: _refreshGameDetails,
          child: CustomScrollView(
            controller: mobileScrollController,
            reverse: false,
            physics: _isPageScrollLocked
                ? const NeverScrollableScrollPhysics() // 锁死！
                : const AlwaysScrollableScrollPhysics(), // 解锁！
            key: ValueKey('game_detail_mobile_${_gameId}_$_refreshCounter'),
            slivers: [
              CustomSliverAppBar(
                titleText: game.title,
                expandedHeight: 300,
                pinned: true,
                flexibleSpaceBackground: flexibleSpaceBackground,
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 80),
                sliver: SliverToBoxAdapter(
                  child: _buildGameContent(game, isPending, isDesktop),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildActionButtonsGroup(context, game, isDesktop),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // 保持位置
    );
  }

  // Desktop Layout 构建
  Widget _buildDesktopLayout(Game game, bool isPending, bool isDesktop) {
    return Scaffold(
      appBar: CustomAppBar(
        title: game.title,
      ),

      body: SingleChildScrollView(
        physics: _isPageScrollLocked
            ? const NeverScrollableScrollPhysics() // 锁死！
            : const AlwaysScrollableScrollPhysics(), // 解锁！
        key: ValueKey('game_detail_desktop_${_gameId}_$_refreshCounter'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildGameContent(game, isPending, isDesktop),
        ),
      ),
      floatingActionButton: _buildActionButtonsGroup(
        context,
        game,
        isDesktop,
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // 指定位置
    );
  }

  Widget _buildGameContent(Game game, bool isPending, bool isDesktop) {
    final bool isPreview = isPending;
    // 当审核状态就代表是预览状态
    return GameDetailLayout(
      gameListFilterProvider: widget.gameListFilterProvider,
      authProvider: widget.authProvider,
      sidebarProvider: widget.sidebarProvider,
      inputStateService: widget.inputStateService,
      gameService: widget.gameService,
      gameCollectionService: widget.gameCollectionService,
      game: game,
      isDesktop: isDesktop,
      infoProvider: widget.infoProvider,
      followService: widget.followService,
      currentUser: widget.authProvider.currentUser,
      initialCollectionStatus: _collectionStatus,
      onCollectionChanged: _handleCollectionStateChangedInButton,
      onNavigate: _handleNavigate,
      navigationInfo: _navigationInfo,
      isPreviewMode: isPreview,
      onRandomSectionHover: (isHovering) {
        setState(() {
          _isPageScrollLocked = isHovering;
        });
      },
      isLiked: _isLiked,
      isCoined: _isCoined,
      isTogglingLike: _isTogglingLike,
      isTogglingCoin: _isTogglingCoin,
      onToggleLike: _handleToggleLike,
      onToggleCoin: _handleToggleCoin,
    );
  }

  Widget _buildPendingContent() {
    return Scaffold(
      appBar: const CustomAppBar(
        // 或者使用通用 AppBar
        title: '游戏详情',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty_rounded,
                  size: 64, color: Colors.orange.shade700),
              const SizedBox(height: 16),
              Text(
                '游戏正在审核中',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '该游戏内容尚未对公众开放，或者您没有权限查看。请等待审核通过后再试。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FunctionalButton(
                // 或者 ElevatedButton
                onPressed: () => NavigationUtils.pop(context),
                label: '返回上一页',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 主 build 方法
  @override
  Widget build(BuildContext context) {
    // 初始 ID 检查
    if (widget.gameDetailParam == null) {
      return const CustomErrorWidget(
        errorMessage: '无效的游戏 ID',
        title: "发生错误",
        useScaffold: true,
      );
    }

    // --- Loading / Error / Content 构建逻辑 ---
    if (_isLoading && _game == null) {
      // 首次加载时全屏 Loading
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

    if (_error != null && _game == null) {
      // --- 使用定义好的错误码常量进行判断 ---
      if (_error == BackendApiErrorCodes.gamePendingApproval) {
        return _buildPendingContent();
      }

      if (_error == BackendApiErrorCodes.notFound) {
        return const NotFoundErrorWidget(
          message: "抱歉，该游戏不存在或已被移除。",
          useScaffold: true,
        );
      }
      // --- 统一处理所有网络相关的错误 ---

      if (BackendApiErrorCodes.networkErrors.contains(_error)) {
        return NetworkErrorWidget(
          onRetry: () => _loadGameDetailsWithStatus(forceRefresh: true),
          useScaffold: true,
        );
      }

      return CustomErrorWidget(
          title: '无法加载游戏数据',
          errorMessage: _error,
          useScaffold: true,
          onRetry: () => _loadGameDetailsWithStatus(forceRefresh: true));
    }

    // 如果 _game 为 null 但不在加载也没错误，显示错误
    if (_game == null) {
      return const CustomErrorWidget(
        title: "无法加载数据",
        errorMessage: '游戏数据不存在',
        useScaffold: true,
      );
    }

    final bool isPending = _game!.approvalStatus == GameStatus.pending;

    Widget bodyContent;
    // --- 处理刷新时的 Loading 状态 (叠加 Loading 指示器) ---
    if (_isLoading && _game != null) {
      // 正在刷新且有旧数据
      bodyContent = const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "少女正在祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    } else {
      bodyContent = LazyLayoutBuilder(
        windowStateProvider: widget.windowStateProvider,
        builder: (context, constraints) {
          final bool isDesktop =
              DeviceUtils.isDesktopInThisWidth(constraints.maxWidth);

          return isDesktop
              ? _buildDesktopLayout(_game!, isPending, isDesktop)
              : _buildMobileLayout(_game!, isPending, isDesktop);
        },
      );
    }
    if (isPending) {
      return Material(
        child: Column(
          children: [
            _buildPendingApprovalBanner(),
            Expanded(child: bodyContent),
          ],
        ),
      );
    } else {
      return bodyContent;
    }
  }
}

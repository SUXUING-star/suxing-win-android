// lib/screens/game/detail/game_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/collection_change_result.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/gamelist/game_list_filter_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/game/collection/game_collection_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/dialogs/info_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_sliver_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart'; // 引入收藏项模型
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 引入认证 Provider
import 'package:suxingchahui/widgets/components/screen/game/game_detail_content.dart'; // 引入内容组件
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 引入桌面 AppBar
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/routes/app_routes.dart';

class GameDetailScreen extends StatefulWidget {
  final String? gameId;
  final bool isNeedHistory;
  final GameCollectionService gameCollectionService;
  final AuthProvider authProvider;
  final GameService gameService;
  final UserInfoProvider infoProvider;
  final UserFollowService followService;
  final InputStateService inputStateService;
  final GameListFilterProvider gameListFilterProvider;
  final SidebarProvider sidebarProvider;
  const GameDetailScreen({
    super.key,
    this.gameId,
    this.isNeedHistory = true,
    required this.authProvider,
    required this.gameCollectionService,
    required this.infoProvider,
    required this.inputStateService,
    required this.gameService,
    required this.gameListFilterProvider,
    required this.followService,
    required this.sidebarProvider,
  });
  @override
  _GameDetailScreenState createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late String? _currentUserId;

  Game? _game;
  GameCollectionItem? _collectionStatus;
  Map<String, dynamic>? _navigationInfo;
  bool? _isLiked; // 父组件持有状态
  String? _error;
  bool _isLoading = false;
  bool _isTogglingLike = false; // 新增：用于跟踪点赞操作的处理状态
  int _refreshCounter = 0;
  bool _hasInitializedDependencies = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _currentUserId = widget.authProvider.currentUserId;
      _hasInitializedDependencies = true;
    }
    if (widget.gameId != null && _hasInitializedDependencies) {
      _isLoading = true;
      // 第一次初始化赋值，之后走下面的流程
      _loadGameDetailsWithStatus(); // 原有的调用
    } else {
      // 处理 null gameId (保持不变，但确保 _isLoading 最后是 false)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = '无效的游戏ID';
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(GameDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool didUpdate = false;

    if (oldWidget.gameId != widget.gameId) {
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
        _error = null;
        _isLoading = true;
        _isTogglingLike = false;
        _refreshCounter = 0; // 可以重置
      });
      // 调用加载逻辑 (保持不变)
      if (widget.gameId != null) {
        _loadGameDetailsWithStatus();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _error = '无效的游戏ID';
              _isLoading = false;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _currentUserId = null;
    _game = null;
    _error = null;
    _isLiked = null;
  }

  // --- 尝试增加游戏浏览次数 ---
  Future<void> _tryIncrementViewCount() async {
    // 检查游戏数据已加载、游戏ID有效、游戏状态为'approved'、且需要记录历史
    if (_game != null &&
        widget.gameId != null &&
        _game!.approvalStatus == GameStatus.approved &&
        widget.isNeedHistory) {
      await widget.gameService.incrementGameView(widget.gameId!);
    }
  }

  // 加载游戏详情和收藏状态
  Future<void> _loadGameDetailsWithStatus({bool forceRefresh = false}) async {
    if (widget.gameId == null || !mounted) return;

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
      result =
          await widget.gameService.getGameDetailsWithStatus(widget.gameId!);
    } catch (e) {
      if (!mounted) return;
      // 检查是否是 "not_found" 异常
      if (e.toString().contains('not_found')) {
        errorMsg = 'not_found';
        gameWasRemoved = true; // *** 标记游戏已被移除 ***

        // *** 显示补偿/移除对话框 ***
        // 使用 addPostFrameCallback 确保在当前帧渲染完成后执行
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // 再次检查 mounted 状态
            CustomInfoDialog.show(
              context: context,
              title: '游戏已移除',
              message: '抱歉，您尝试访问的游戏已被移除或不存在。\n(这里可以放补偿说明，如果需要的话)',
              iconData: Icons
                  .delete_forever_outlined, // 或者 Icons.sentiment_very_dissatisfied
              iconColor: Colors.redAccent,
              closeButtonText: '知道了',
              barrierDismissible: false, // 不允许点击外部关闭，强制用户确认
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
        // 处理其他已知错误
      } else if (e.toString().contains('game_pending_approval')) {
        errorMsg = 'pending_approval';
      } else if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('SocketException')) {
        errorMsg = 'network_error';
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
            _error = null;
          } else {
            // 加载/刷新失败，但游戏 *并未* 被移除
            if (_game == null) {
              // 首次失败
              _error = errorMsg ?? '未知错误';
              _isLiked = null;
            } else {
              // 刷新失败
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  AppSnackBar.showError(context, "刷新失败: ${errorMsg ?? '未知错误'}");
                }
              });
              // 保留旧数据，只显示 Toaster
            }
          }
          _isLoading = false;
          _isTogglingLike = false;
          _refreshCounter++;
        });
        await _tryIncrementViewCount();
      } else if (mounted && gameWasRemoved) {
        // 如果游戏被移除，我们不应该更新 _game 等状态
        // 只需确保 loading 状态结束
        setState(() {
          _isLoading = false;
          _isTogglingLike = false;
        });
      }
    }
  }

  // 刷新逻辑
  Future<void> _refreshGameDetails() async {
    if (!mounted || widget.gameId == null) return;

    // 调用加载，forceRefresh 确保即使短时间内连续操作也会尝试重新加载
    await _loadGameDetailsWithStatus(forceRefresh: true);
  }

  Future<void> _handleCollectionStateChangedInButton(
      CollectionChangeResult result) async {
    // 1. 安全检查
    if (!mounted || _game == null) {
      return;
    }

    // 2. 获取当前状态和变化信息
    final Game currentGame = _game!;
    final Map<String, int> countDeltas = result.countDeltas; // 收藏计数增量 (来自按钮的回调)
    final GameCollectionItem? newCollectionItem = result.newStatus;
    final GameCollectionItem? oldCollectionItem =
        _collectionStatus; // 使用屏幕 State 中记录的旧状态

    // 3. 计算评分的 Delta (前端计算)
    double deltaRatingSum = 0;
    int deltaRatingCount = 0;
    final oldStatusString = oldCollectionItem?.status;
    final newStatusString = newCollectionItem?.status;
    final oldRatingValue = oldCollectionItem?.rating;
    final newRatingValue = newCollectionItem?.rating;

    bool oldHadRating = oldStatusString == GameCollectionStatus.played &&
        oldRatingValue != null;
    bool newHasRating = newStatusString == GameCollectionStatus.played &&
        newRatingValue != null;

    if (!oldHadRating && newHasRating) {
      deltaRatingSum = newRatingValue;
      deltaRatingCount = 1;
    } else if (oldHadRating && newHasRating) {
      if (oldRatingValue != newRatingValue) {
        deltaRatingSum = newRatingValue - oldRatingValue;
      }
    } else if (oldHadRating && !newHasRating) {
      deltaRatingSum = -oldRatingValue;
      deltaRatingCount = -1;
    }

    // 4. 计算补偿后的新评分统计数据和平均分
    final int newRatingCount =
        (currentGame.ratingCount + deltaRatingCount).clamp(0, 1000000);
    final double newTotalRatingSum = (newRatingCount == 0)
        ? 0.0
        : (currentGame.totalRatingSum + deltaRatingSum);

    // *** 在前端计算平均分 ***
    double newAverageRating = 0.0;
    if (newRatingCount > 0) {
      newAverageRating = newTotalRatingSum / newRatingCount;
      // 保留一位小数 (可选)
      newAverageRating = (newAverageRating * 10).round() / 10;
    }
    // 限制在 0 到 10 之间 (可选，增加健壮性)
    newAverageRating = newAverageRating.clamp(0.0, 10.0);

    // 5. 使用 copyWith 创建包含所有补偿后数据的新 Game 对象
    final Game updatedGame = currentGame.copyWith(
      // 补偿收藏计数
      wantToPlayCount:
          (currentGame.wantToPlayCount + (countDeltas['want'] ?? 0))
              .clamp(0, 1000000),
      playingCount: (currentGame.playingCount + (countDeltas['playing'] ?? 0))
          .clamp(0, 1000000),
      playedCount: (currentGame.playedCount + (countDeltas['played'] ?? 0))
          .clamp(0, 1000000),
      totalCollections:
          (currentGame.totalCollections + (countDeltas['total'] ?? 0))
              .clamp(0, 1000000),
      ratingCount: newRatingCount,
      totalRatingSum: newTotalRatingSum,
      rating: newAverageRating, // *** 使用前端计算的新平均分 ***
      updateTime: DateTime.now(), // 更新游戏整体更新时间
      ratingUpdateTime: (deltaRatingCount != 0 || deltaRatingSum != 0)
          ? DateTime.now()
          : currentGame.ratingUpdateTime,
    );

    try {
      // 确保使用 dialog 返回的最新 status (result.newStatus) 来缓存
      await widget.gameService.cacheNewData(updatedGame, result.newStatus);
      // 6. 使用 setState 更新状态 (在缓存成功后)
      // 不再需要加延迟，await 已经保证了顺序
      if (mounted) {
        // 再次检查 mounted 状态，因为 await 可能耗时
        setState(() {
          _collectionStatus = result.newStatus; // 更新收藏按钮状态
          _game = updatedGame; // *** 更新包含所有补偿后数据的 game 对象 ***
          _refreshCounter++; // 强制子组件重建
        });
      }
    } catch (cacheError) {
      //
    }
  }

  // 处理点赞切换的回调函数
  Future<void> _handleToggleLike() async {
    // 保持前置检查
    if (widget.gameId == null || _isTogglingLike || !mounted) return;

    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    setState(() {
      _isTogglingLike = true; // 开始按钮 loading
    });

    try {
      // 调用返回 Future<bool> 的 service 方法
      final newIsLikedStatus =
          await widget.gameService.toggleLike(widget.gameId!);

      if (mounted) {
        // 异步操作后再次检查 mounted
        setState(() {
          _isLiked = newIsLikedStatus; // 直接更新点赞状态
        });
        AppSnackBar.showSuccess(context, newIsLikedStatus ? '点赞成功' : '已取消点赞');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
            context, '操作失败: ${e.toString().split(':').last.trim()}');
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
      AppSnackBar.showError(context, "你没有权限操作");
      return;
    }
    final result = await NavigationUtils.pushNamed(context, AppRoutes.editGame,
        arguments: game.id);
    if (result == true && mounted) {
      _refreshGameDetails(); // 强制刷新
    }
  }

  /// Handles delete action (using your original onConfirm logic).
  Future<void> _handleDeletePressed(Game game) async {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }
    if (!_canEditOrDeleteGame(game)) {
      AppSnackBar.showError(context, "你没有权限编辑");
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
          AppSnackBar.showSuccess(context, "成功删除游戏");
        } catch (e) {
          AppSnackBar.showError(context, "删除游戏失败");
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

  Widget _buildActionButtonsGroup(BuildContext context, Game game) {
    final String editHeroTag = MediaQuery.of(context).size.width >= 1024
        ? 'editButtonDesktop'
        : 'editButtonMobile';
    final String deleteHeroTag = MediaQuery.of(context).size.width >= 1024
        ? 'deleteButtonDesktop'
        : 'deleteButtonMobile';
    final String likeHeroTag = MediaQuery.of(context).size.width >= 1024
        ? 'likeButtonDesktop'
        : 'likeButtonMobile'; // 给点赞按钮也加上区分的 heroTag

    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color greyColor = Colors.grey.shade600; // 用于未点赞状态的颜色（可选）

    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream,
      initialData: widget.authProvider.currentUser,
      builder: (context, currentUserSnapshot) {
        final User? currentUser = currentUserSnapshot.data;
        if (currentUser == null) return const SizedBox.shrink();
        final bool isAdmin = currentUser.isAdmin;
        final bool canEdit = isAdmin ? true : currentUser.id == game.authorId;
        return Padding(
          // 给整个按钮组添加统一的外边距
          padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          child: FloatingActionButtonGroup(
            spacing: 16.0, // 按钮间距
            alignment: MainAxisAlignment.end, // 底部对齐
            children: [
              // --- 第一个按钮：点赞按钮或占位符 ---
              if (_isLiked != null) // 确保状态已加载
                GenericFloatingActionButton(
                  key: ValueKey('like_fab_${widget.gameId}'),
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
                  // 点击回调保持不变
                  isLoading: _isTogglingLike, // 把加载状态传递给通用 FAB
                )
              else
                // 加载占位符 (保持不变)
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))),
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
            key: ValueKey(
                'game_detail_mobile_${widget.gameId}_$_refreshCounter'),
            slivers: [
              CustomSliverAppBar(
                titleText: game.title,
                expandedHeight: 300,
                pinned: true,
                flexibleSpaceBackground: flexibleSpaceBackground,
                actions: [
                  IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {},
                      tooltip: '分享'),
                ],
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
      // --- 直接调用辅助方法构建 FAB 组 ---
      floatingActionButton: _buildActionButtonsGroup(context, game),
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
        key: ValueKey('game_detail_desktop_${widget.gameId}_$_refreshCounter'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildGameContent(game, isPending, isDesktop),
        ),
      ),
      floatingActionButton: _buildActionButtonsGroup(context, game),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // 指定位置
    );
  }

  Widget _buildGameContent(Game game, bool isPending, bool isDesktop) {
    final bool isPreview = isPending ? true : false;
    return GameDetailContent(
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
              SizedBox(height: 16),
              Text(
                '游戏正在审核中',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                '该游戏内容尚未对公众开放，或者您没有权限查看。请等待审核通过后再试。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 24),
              FunctionalTextButton(
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
    if (widget.gameId == null) {
      return const CustomErrorWidget(
        errorMessage: '无效的游戏 ID',
        isNeedLoadingAnimation: true,
      );
    }

    // --- Loading / Error / Content 构建逻辑 ---
    if (_isLoading && _game == null) {
      // 首次加载时全屏 Loading
      return FadeInItem(
          child: LoadingWidget.fullScreen(message: '正在加载游戏数据...'));
    }

    if (_error != null && _game == null) {
      if (_error == 'pending_approval') {
        // --- 返回特定的“审核中/无权查看”UI ---
        return _buildPendingContent();
      }
      // 首次加载失败时全屏 Error
      if (_error == 'not_found' && _game == null) {
        return const NotFoundErrorWidget(message: "抱歉，该游戏不存在或已被移除。");
      }
      if (_error == 'network_error') {
        return NetworkErrorWidget(
            onRetry: () => _loadGameDetailsWithStatus(forceRefresh: true));
      }
      return CustomErrorWidget(
          title: '无法加载游戏数据',
          errorMessage: _error,
          onRetry: () => _loadGameDetailsWithStatus(forceRefresh: true));
    }

    // 如果 _game 为 null 但不在加载也没错误，显示错误
    if (_game == null) {
      return const CustomErrorWidget(
        title: "无法加载数据",
        errorMessage: '游戏数据不存在',
      );
    }

    final bool isPending = _game!.approvalStatus == GameStatus.pending;

    Widget bodyContent;
    // --- 处理刷新时的 Loading 状态 (叠加 Loading 指示器) ---
    if (_isLoading && _game != null) {
      // 正在刷新且有旧数据
      bodyContent = LoadingWidget.fullScreen(message: "正在加载游戏数据");
    } else {
      final isDesktop = MediaQuery.of(context).size.width >= 1024;

      bodyContent = isDesktop
          ? _buildDesktopLayout(_game!, isPending, isDesktop)
          : _buildMobileLayout(_game!, isPending, isDesktop);
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

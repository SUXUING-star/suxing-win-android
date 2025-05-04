// lib/screens/game/detail/game_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/game/collection_change_result.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
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
  const GameDetailScreen({super.key, this.gameId, this.isNeedHistory = true});
  @override
  _GameDetailScreenState createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late AuthProvider _authProvider;

  Game? _game;
  GameCollectionItem? _collectionStatus;
  Map<String, dynamic>? _navigationInfo;
  bool? _isLiked; // 父组件持有状态
  String? _error;
  bool _isLoading = false;
  bool _isTogglingLike = false; // 新增：用于跟踪点赞操作的处理状态
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (widget.gameId != null) {
      _isLoading = true;
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
    if (oldWidget.gameId != widget.gameId) {
      // *** 这里是改动：调用加载前，用 setState 设置 _isLoading = true ***
      setState(() {
        _game = null;
        _collectionStatus = null;
        _navigationInfo = null;
        _isLiked = null;
        _error = null;
        _isLoading = true; // <--- 在 setState 里设置
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

  // --- 新增: 尝试增加游戏浏览次数 ---
  void _tryIncrementViewCount() {
    // 检查游戏数据已加载、游戏ID有效、游戏状态为'approved'、且需要记录历史
    if (_game != null &&
            widget.gameId != null &&
            _game!.approvalStatus == GameStatus.approved && // <--- 检查状态
            widget.isNeedHistory // <--- 检查是否需要记录历史 (预览模式判断)
        ) {
      final gameService = context.read<GameService>();
      gameService.incrementGameView(widget.gameId!).catchError((error) {});
    } else {
      // 打印跳过原因，方便调试
      //print(
      //    "GameDetailScreen (${widget.gameId}): Skipping view count increment. Status: ${_game?.approvalStatus}, NeedHistory: ${widget.isNeedHistory}");
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
      final gameService = context.read<GameService>();
      result = await gameService.getGameDetailsWithStatus(widget.gameId!);
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
                      // 如果不能 pop (比如是根路由)，可以导航到主页
                      NavigationUtils.pushReplacementNamed(
                          context, AppRoutes.home);
                    }
                  } catch (popError) {
                    // 备用方案：导航到主页
                    NavigationUtils.pushReplacementNamed(
                        context, AppRoutes.home);
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
            print("设置_game状态");
            _game = result.game;
            _collectionStatus = result.collectionStatus;
            _navigationInfo = result.navigationInfo;
            _isLiked = result.isLiked;
            _error = null;
            _tryIncrementViewCount();
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
      // *** 补偿评分相关字段 ***
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
      final gameService = context.read<GameService>();
      await gameService.cachedNewData(updatedGame, result.newStatus);
      //print("GameDetailScreen (${widget.gameId}): Cache updated successfully before setState.");

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
    } catch (cacheError) {}
  }

  // *** 核心改动：处理点赞切换的回调函数 ***
  Future<void> _handleToggleLike() async {
    // 保持前置检查
    if (widget.gameId == null || _isTogglingLike || !mounted) return;
    if (!_authProvider.isLoggedIn) {
      AppSnackBar.showWarning(context, '请先登录');
      NavigationUtils.pushNamed(context, AppRoutes.login);
      return;
    }

    setState(() {
      _isTogglingLike = true; // 开始按钮 loading
    });

    try {
      // 调用返回 Future<bool> 的 service 方法
      final gameService = context.read<GameService>();
      final newIsLikedStatus = await gameService.toggleLike(widget.gameId!);

      // *** 直接用返回结果更新状态 ***
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
      // *** 结束按钮 loading ***
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
  bool _canEditGame(BuildContext context, Game game) {
    final canEdit = _authProvider.isAdmin ||
        (_authProvider.isLoggedIn &&
            _authProvider.currentUser?.id == game.authorId);
    return canEdit;
  }

  // 处理编辑按钮点击事件
  void _handleEditPressed(BuildContext context, Game game) async {
    //print("GameDetailScreen (${widget.gameId}): Edit button pressed.");
    final result = await NavigationUtils.pushNamed(context, AppRoutes.editGame,
        arguments: game);
    if (result == true && mounted) {
      _refreshGameDetails(); // 强制刷新
    } else {}
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
    final bool canEdit = _canEditGame(context, game);
    final String editHeroTag = MediaQuery.of(context).size.width >= 1024
        ? 'editButtonDesktop'
        : 'editButtonMobile';
    final String likeHeroTag = MediaQuery.of(context).size.width >= 1024
        ? 'likeButtonDesktop'
        : 'likeButtonMobile'; // 给点赞按钮也加上区分的 heroTag

    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color greyColor = Colors.grey.shade600; // 用于未点赞状态的颜色（可选）

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
              key: ValueKey('like_fab_${widget.gameId}'), // 使用 FAB 特定的 Key
              heroTag: likeHeroTag,
              backgroundColor: Colors.white,
              tooltip: _isLiked! ? '取消点赞' : '点赞', // 根据状态显示不同提示
              icon: _isLiked!
                  ? Icons.favorite
                  : Icons.favorite_border, // 根据状态切换图标
              // --- 颜色控制 (示例) ---
              // 点赞时使用主题色，未点赞时使用灰色或默认色
              foregroundColor: _isLiked! ? primaryColor : greyColor,
              onPressed: _handleToggleLike, // 点击回调保持不变
              isLoading: _isTogglingLike, // 把加载状态传递给通用 FAB
              // 可以调整大小，比如都用 mini？或者保持默认大小
              // mini: true,
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

          // --- 第二个按钮：编辑按钮 (如果允许) ---
          if (canEdit)
            GenericFloatingActionButton(
              heroTag: editHeroTag, // 使用区分后的 heroTag
              mini: true, // 统一使用 mini 尺寸，或根据需要调整
              tooltip: '编辑',
              icon: Icons.edit,
              onPressed: () => _handleEditPressed(context, game),
              backgroundColor: Colors.white, // 白色背景
              foregroundColor: Theme.of(context).primaryColor, // 主题色图标
            ),
        ],
      ),
    );
  }

  // Mobile Layout 构建
  Widget _buildMobileLayout(Game game, bool isPending) {
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
      // **** [核心改动] 用 Scrollbar 包裹 RefreshIndicator ****
      body: Scrollbar(
        // <--- 添加 Scrollbar
        interactive: false,
        controller: mobileScrollController, // <--- 传入 Controller
        thumbVisibility: true, // <--- 让滚动条一直可见 (或者 isAlwaysShown: true)
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
                  child: _buildGameContent(game, isPending),
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
  Widget _buildDesktopLayout(Game game, bool isPending) {
    return Scaffold(
      appBar: CustomAppBar(
        title: game.title,
      ),

      body: SingleChildScrollView(
        key: ValueKey('game_detail_desktop_${widget.gameId}_$_refreshCounter'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildGameContent(game, isPending),
        ),
      ),
      floatingActionButton: _buildActionButtonsGroup(context, game),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // 指定位置
    );
  }

  Widget _buildGameContent(Game game, bool isPending) {
    final bool isPreview = isPending ? true : false;
    return GameDetailContent(
      game: game,
      initialCollectionStatus: _collectionStatus,
      onCollectionChanged: _handleCollectionStateChangedInButton, // <--- 传递这个函数
      onNavigate: _handleNavigate,
      navigationInfo: _navigationInfo,
      isPreviewMode: isPreview,
    );
  }

  // 主 build 方法
  @override
  Widget build(BuildContext context) {
    // 初始 ID 检查
    if (widget.gameId == null) {
      return CustomErrorWidget(
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
        return Scaffold(
          appBar: CustomAppBar(
            // 或者使用通用 AppBar
            title: '游戏详情',
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => NavigationUtils.pop(context), // 提供返回按钮
            ),
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
      // 首次加载失败时全屏 Error
      if (_error == 'not_found' && _game == null) {
        // 这个页面可能在对话框关闭后、导航完成前的短暂瞬间显示
        // 或者如果对话框弹出失败，会显示这个
        return NotFoundErrorWidget(
            message: "抱歉，该游戏不存在或已被移除。",
            onBack: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                NavigationUtils.navigateToHome(context);
              }
            });
      }
      if (_error == 'network_error') {
        return NetworkErrorWidget(
            onRetry: () => _loadGameDetailsWithStatus(forceRefresh: true));
      }
      if (_error == 'pending_approval') {
        return Scaffold(
          appBar: CustomAppBar(
            title: '游戏详情',
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => NavigationUtils.pop(context),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_actions, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  '游戏正在审核中',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '该游戏正在等待管理员审核，审核通过后将可以查看。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 24),
                FunctionalTextButton(
                  onPressed: () => NavigationUtils.pop(context),
                  label: '返回',
                ),
              ],
            ),
          ),
        );
      }
      return CustomErrorWidget(
          title: '无法加载游戏数据',
          errorMessage: _error,
          onRetry: () => _loadGameDetailsWithStatus(forceRefresh: true));
    }

    // 如果 _game 为 null 但不在加载也没错误，显示错误
    if (_game == null) {
      return CustomErrorWidget(
        title: "无法加载数据",
        errorMessage: '游戏数据不存在',
      );
    }

    final bool isPending = _game!.approvalStatus == 'pending';

    Widget bodyContent;
    // --- 处理刷新时的 Loading 状态 (叠加 Loading 指示器) ---
    if (_isLoading && _game != null) {
      // 正在刷新且有旧数据
      bodyContent = LoadingWidget.fullScreen(message: "正在加载游戏数据");
    } else {
      // 正常渲染
      final isDesktop = MediaQuery.of(context).size.width >= 1024;

      bodyContent = isDesktop
          ? _buildDesktopLayout(_game!, isPending)
          : _buildMobileLayout(_game!, isPending);
    }
    if (isPending) {
      // 如果是 pending，返回 Material -> Column -> [Banner, Expanded(bodyContent)]
      return Material(
        // 用 Material 做根，保证背景和主题
        child: Column(
          children: [
            _buildPendingApprovalBanner(), // 调用你已有的 Banner 方法
            Expanded(child: bodyContent), // 把 Scaffold 或 LoadingWidget 放下面填满
          ],
        ),
      );
    } else {
      // 如果不是 pending，直接返回 bodyContent (它自己是 Scaffold 或 LoadingWidget)
      return bodyContent;
    }
  }
}

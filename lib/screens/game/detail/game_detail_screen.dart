// lib/screens/game/detail/game_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/game/collection_change_result.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/toaster/toaster.dart';
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
  const GameDetailScreen({Key? key, this.gameId}) : super(key: key);
  @override
  _GameDetailScreenState createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final GameService _gameService = GameService();
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
      // *** 这里是改动：调用加载前，直接设置 _isLoading = true ***
      // 因为 initState 不会立即触发 build，直接改成员变量就行
      _isLoading = true;
      _loadGameDetailsWithStatus(); // 原有的调用
      _incrementViewCount(); // 原有的调用
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
        _incrementViewCount();
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

  // 加载游戏详情和收藏状态
  Future<void> _loadGameDetailsWithStatus({bool forceRefresh = false}) async {
    if (widget.gameId == null || !mounted) return; // 保持检查

    // 确保 isLoading 是 true (如果调用前没设置好)
    if (!_isLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    GameDetailsWithStatus? result;
    String? errorMsg;
    try {
      // 调用 service (保持不变)
      result = await _gameService.getGameDetailsWithStatus(widget.gameId!);
      if (result == null && mounted) {
        errorMsg = 'not_found';
      }
    } catch (e) {
      if (!mounted) return;
      print(
          "GameDetailScreen (${widget.gameId}): Error loading details with status: $e");
      // 错误处理 (保持不变)
      if (e.toString().contains('game_pending_approval')) {
        errorMsg = 'pending_approval';
      } else if (e.toString().contains('not_found')) {
        errorMsg = 'not_found';
      } else if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('SocketException')) {
        errorMsg = 'network_error';
      } else {
        errorMsg = '加载失败: ${e.toString()}';
      }
    } finally {
      if (mounted) {
        setState(() {
          // <--- 必须用 setState
          if (errorMsg == null && result != null) {
            // 成功逻辑 (保持不变)
            _game = result.game;
            _collectionStatus = result.collectionStatus;
            _navigationInfo = result.navigationInfo;
            _isLiked = result.isLiked;
            _error = null;
          } else {
            // 失败逻辑 (保持不变)
            if (_game == null) {
              // 首次失败
              _error = errorMsg ?? '未知错误';
              _isLiked = null;
            } else {
              // 刷新失败
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted)
                  Toaster.show(context,
                      message: "刷新失败: ${errorMsg ?? '未知错误'}", isError: true);
              });
            }
          }
          _isLoading = false; // <--- 核心改动：保证加载结束
          _isTogglingLike = false; // 顺便重置
          _refreshCounter++;
          print(
              "GameDetailScreen (${widget.gameId}): FINALLY - setState finished. isLoading is now: $_isLoading");
        });
      }
    }
  }

  // 刷新逻辑
  Future<void> _refreshGameDetails() async {
    if (!mounted || widget.gameId == null) return;
    print(
        "GameDetailScreen (${widget.gameId}): Refreshing details (forcing cache clear)...");

    // 调用加载，forceRefresh 确保即使短时间内连续操作也会尝试重新加载
    await _loadGameDetailsWithStatus(forceRefresh: true);
  }

  // 增加游戏浏览次数
  void _incrementViewCount() {
    if (widget.gameId != null) {
      _gameService.incrementGameView(widget.gameId!);
    }
  }

  void _handleCollectionStateChangedInButton(CollectionChangeResult result) {

    if (mounted && _game != null) {
      // 确保已挂载且 _game 对象存在
      // 1. 使用 copyWith 创建一个新的 Game 对象，并应用增量 (前端补偿计数值)
      final Game currentGame = _game!;
      final Map<String, int> deltas = result.countDeltas;

      final Game updatedGame = currentGame.copyWith(
        // *** 只修改需要变化的字段 ***
        wantToPlayCount: currentGame.wantToPlayCount + (deltas['want'] ?? 0),
        playingCount: currentGame.playingCount + (deltas['playing'] ?? 0),
        playedCount: currentGame.playedCount + (deltas['played'] ?? 0),
        totalCollections: currentGame.totalCollections + (deltas['total'] ?? 0),
        updateTime: DateTime.now(), // 可选：更新 updateTime 以反映本地状态变化
      );

      // 2. 使用 setState 更新状态
      setState(() {
        _collectionStatus = result.newStatus; // 更新收藏状态对象
        _game = updatedGame; // *** 更新游戏对象，包含补偿后的计数值 ***
        _refreshCounter++; // 增加计数器，确保依赖 _game 的子组件重建
      });
    } else {
      print(
          'GameDetailScreen (${widget.gameId}): Cannot apply collection change, component unmounted or game data is null.');
    }
  }

  // *** 核心改动：处理点赞切换的回调函数 ***
  // *** 这个函数需要完全替换掉你原来的 _handleToggleLike ***
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
      final newIsLikedStatus = await _gameService.toggleLike(widget.gameId!);

      // *** 直接用返回结果更新状态 ***
      if (mounted) {
        // 异步操作后再次检查 mounted
        setState(() {
          _isLiked = newIsLikedStatus; // 直接更新点赞状态
        });
        AppSnackBar.showSuccess(context,newIsLikedStatus ? '点赞成功' : '已取消点赞');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '操作失败: ${e.toString().split(':').last.trim()}');
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => GameDetailScreen(gameId: gameId)),
    );
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
    print("GameDetailScreen (${widget.gameId}): Edit button pressed.");
    final result = await NavigationUtils.pushNamed(context, AppRoutes.editGame,
        arguments: game);
    if (result == true && mounted) {
      print(
          "GameDetailScreen (${widget.gameId}): Game edited, refreshing details.");
      _refreshGameDetails(); // 强制刷新
    } else {
      print(
          "GameDetailScreen (${widget.gameId}): Edit page returned without saving or widget unmounted.");
    }
  }

  // --- UI 构建方法 ---

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

          // --- 如果有其他通用按钮，可以加在这里 ---
        ],
      ),
    );
  }

  // Mobile Layout 构建
  Widget _buildMobileLayout(Game game) {
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshGameDetails,
        child: CustomScrollView(
          key: ValueKey('game_detail_mobile_${widget.gameId}_$_refreshCounter'),
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
                child: GameDetailContent(
                  // 传递数据给 Content
                  game: game,
                  initialCollectionStatus: _collectionStatus, // <--- 传递状态
                  onCollectionChanged:
                      _handleCollectionStateChangedInButton, // <--- 传递这个函数
                  onNavigate: _handleNavigate,
                  navigationInfo: _navigationInfo,
                ),
              ),
            ),
          ],
        ),
      ),
      // --- 直接调用辅助方法构建 FAB 组 ---
      floatingActionButton: _buildActionButtonsGroup(context, game),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // 保持位置
    );
  }

  // Desktop Layout 构建
  Widget _buildDesktopLayout(Game game) {
    final bool canEdit = _canEditGame(context, game);
    return Scaffold(
      appBar: CustomAppBar(
        title: game.title,
        actions: [
          IconButton(
              icon: const Icon(Icons.share), onPressed: () {}, tooltip: '分享'),
        ],
      ),
      body: SingleChildScrollView(
        key: ValueKey('game_detail_desktop_${widget.gameId}_$_refreshCounter'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: GameDetailContent(
            game: game,
            initialCollectionStatus: _collectionStatus,
            onCollectionChanged:
                _handleCollectionStateChangedInButton, // <--- 传递这个函数
            onNavigate: _handleNavigate,
            navigationInfo: _navigationInfo,
          ),
        ),
      ),
      floatingActionButton: _buildActionButtonsGroup(context, game),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // 指定位置
    );
  }

  // 主 build 方法
  @override
  Widget build(BuildContext context) {
    // 初始 ID 检查
    if (widget.gameId == null) {
      return CustomErrorWidget(errorMessage: '无效的游戏 ID');
    }

    // --- Loading / Error / Content 构建逻辑 ---
    if (_isLoading && _game == null) {
      // 首次加载时全屏 Loading
      return LoadingWidget.fullScreen(message: '加载中...');
    }

    if (_error != null && _game == null) {
      // 首次加载失败时全屏 Error
      if (_error == 'not_found') {
        return NotFoundErrorWidget(onBack: () => NavigationUtils.of(context).pop());
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
      return InlineErrorWidget(errorMessage: '无法加载游戏数据');
    }

    // --- 正常渲染游戏内容 ---
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    Widget bodyContent =
        isDesktop ? _buildDesktopLayout(_game!) : _buildMobileLayout(_game!);

    // --- 处理刷新时的 Loading 状态 (叠加 Loading 指示器) ---
    if (_isLoading && _game != null) {
      // 正在刷新且有旧数据
      bodyContent = LoadingWidget.inline(message: "正在加载数据");
    }
    // --- ---

    return bodyContent; // 返回最终构建的 Widget
  }
}

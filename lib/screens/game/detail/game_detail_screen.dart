// lib/screens/game/detail/game_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/services/main/game/cache/game_cache_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_sliver_app_bar.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';

// --- 引入必要的模型和服务 ---
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/models/game/game_collection.dart'; // 引入收藏项模型
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 引入认证 Provider
// --- ---

import 'package:suxingchahui/widgets/components/screen/game/button/like_button.dart';
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
  final GameCacheService _gameCacheService = GameCacheService();
  late AuthProvider _authProvider;

  Game? _game;
  GameCollectionItem? _collectionStatus; // 保存收藏状态
  Map<String, dynamic>? _navigationInfo; // <--- 在这里加上这一行
  String? _error;
  bool _isLoading = false; // 初始为 false
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    print("GameDetailScreen (${widget.gameId}): initState called");
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (widget.gameId != null) {
      _loadGameDetailsWithStatus(); // 调用新的加载方法
      _incrementViewCount();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted){ setState(() { _error = '无效的游戏ID'; /* isLoading 已经是 false */ }); }
      });
    }
  }

  @override
  void didUpdateWidget(GameDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      print("GameDetailScreen (${widget.gameId}): gameId changed, reloading details with status");
      _loadGameDetailsWithStatus();
      _incrementViewCount();
    }
  }

  // 加载游戏详情和收藏状态
  Future<void> _loadGameDetailsWithStatus({bool forceRefresh = false}) async {
    if (widget.gameId == null || !mounted) return;
    // 如果不是强制刷新且已在加载中，则返回
    if (_isLoading && !forceRefresh) {
      print("GameDetailScreen (${widget.gameId}): Already loading, skipping duplicate request.");
      return;
    }

    print("GameDetailScreen (${widget.gameId}): Loading game details with status (forceRefresh: $forceRefresh)...");
    bool startedLoading = false; // 标记是否真的开始了加载
    if (mounted) {
      setState(() {
        _isLoading = true; // 开始加载
        _error = null;
      });
      startedLoading = true;
    } else {
      return;
    }

    GameDetailsWithStatus? result;
    String? errorMsg;
    try {
      result = await _gameService.getGameDetailsWithStatus(widget.gameId!);
      if (result == null) { errorMsg = 'not_found'; }
    } catch (e) {
      if (!mounted) return; // 异步异常后检查
      print("GameDetailScreen (${widget.gameId}): Error loading details with status: $e");
      if (e.toString().contains('game_pending_approval')) { errorMsg = 'pending_approval'; }
      else if (e.toString().contains('not_found')) { errorMsg = 'not_found'; }
      else { errorMsg = '加载失败，请稍后重试'; }
    } finally {
      if (mounted && startedLoading) { // 只有开始了加载才需要结束
        setState(() {
          if (errorMsg == null && result != null) {
            _game = result.game;
            _collectionStatus = result.collectionStatus;
            _navigationInfo = result.navigationInfo;
            _error = null;
            print("GameDetailScreen (${widget.gameId}): Details loaded successfully.");
          } else {
            _error = errorMsg ?? '未知错误';
            print("GameDetailScreen (${widget.gameId}): Failed to load details. Error: $_error");
            // 保留旧的 _game 数据以供显示，只更新错误信息
          }
          _isLoading = false; // 结束加载
          _refreshCounter++;
        });
      }
    }
  }

  // 刷新逻辑
  Future<void> _refreshGameDetails() async {
    if (!mounted || widget.gameId == null) return;
    print("GameDetailScreen (${widget.gameId}): Refreshing details (forcing cache clear)...");
    final userId = await _authProvider.currentUserId;
    final cacheKey = 'game_details_with_status_${userId ?? "guest"}_${widget.gameId}';
    await _gameCacheService.clearRawDataCacheByKey(cacheKey);
    print("GameDetailScreen (${widget.gameId}): Cache cleared for key: $cacheKey before refresh");
    await _loadGameDetailsWithStatus(forceRefresh: true); // 强制刷新
    _incrementViewCount();
  }

  // 增加游戏浏览次数
  void _incrementViewCount() {
    if (widget.gameId != null) {
      print("GameDetailScreen (${widget.gameId}): Incrementing view count.");
      _gameService.incrementGameView(widget.gameId!);
    }
  }

  // 处理点赞状态变化的回调
  void _handleLikeChanged() {
    print("GameDetailScreen (${widget.gameId}): Like changed, reloading details without force refresh.");
    _loadGameDetailsWithStatus(); // 普通刷新
  }

  // 处理游戏导航的回调
  void _handleNavigate(String gameId) {
    print("GameDetailScreen (${widget.gameId}): Navigating to game $gameId");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => GameDetailScreen(gameId: gameId)),
    );
  }

  // 检查当前用户是否有权限编辑游戏
  bool _canEditGame(BuildContext context, Game game) {
    final canEdit = _authProvider.isAdmin || (_authProvider.isLoggedIn && _authProvider.currentUser?.id == game.authorId);
    return canEdit;
  }

  // 处理编辑按钮点击事件
  void _handleEditPressed(BuildContext context, Game game) async {
    print("GameDetailScreen (${widget.gameId}): Edit button pressed.");
    final result = await NavigationUtils.pushNamed(context, AppRoutes.editGame, arguments: game);
    if (result == true && mounted) {
      print("GameDetailScreen (${widget.gameId}): Game edited, refreshing details.");
      _refreshGameDetails(); // 强制刷新
    } else {
      print("GameDetailScreen (${widget.gameId}): Edit page returned without saving or widget unmounted.");
    }
  }

  // 处理收藏状态变化的回调
  Future<void> _handleCollectionChanged() async {
    print("GameDetailScreen (${widget.gameId}): Collection changed callback received.");
    await _refreshGameDetails(); // 强制刷新
  }

  // --- UI 构建方法 ---

  // Mobile Layout 构建
  Widget _buildMobileLayout(Game game) {
    final bool canEdit = _canEditGame(context, game);
    final flexibleSpaceBackground = Stack(
      fit: StackFit.expand,
      children: [
        SafeCachedImage(imageUrl: game.coverImage, fit: BoxFit.cover,),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.5, 1.0], colors: [ Colors.transparent, Colors.black87, ],),),),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, stops: [0.8, 1.0], colors: [ Colors.transparent, Colors.black38, ],),),),
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
                IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () {}, tooltip: '分享'),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 80),
              sliver: SliverToBoxAdapter(
                child: GameDetailContent( // 传递数据给 Content
                  game: game,
                  initialCollectionStatus: _collectionStatus, // <--- 传递状态
                  onCollectionChanged: _handleCollectionChanged, // <--- 传递回调
                  onNavigate: _handleNavigate,
                  navigationInfo: _navigationInfo,      // <--- 加上这一行
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 32.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            LikeButton(game: game, gameService: _gameService, onLikeChanged: _handleLikeChanged),
            // 收藏按钮在 GameDetailContent -> GameCollectionSection 内部渲染
            if (canEdit) ...[
              const SizedBox(width: 16.0),
              FloatingActionButton(heroTag: 'editButtonMobile', mini: true, onPressed: () => _handleEditPressed(context, game), child: Icon(Icons.edit), backgroundColor: Colors.white, foregroundColor: Theme.of(context).primaryColor,),
            ]
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Desktop Layout 构建
  Widget _buildDesktopLayout(Game game) {
    final bool canEdit = _canEditGame(context, game);
    return Scaffold(
      appBar: CustomAppBar(
        title: game.title,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}, tooltip: '分享'),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: LikeButton(game: game, gameService: _gameService, onLikeChanged: _handleLikeChanged,),),
          // 收藏按钮在 GameDetailContent -> GameCollectionSection 内部渲染
          if (canEdit) Padding(padding: const EdgeInsets.only(right: 16.0), child: IconButton(icon: const Icon(Icons.edit), tooltip: '编辑', onPressed: () => _handleEditPressed(context, game),),),
        ],
      ),
      body: SingleChildScrollView(
        key: ValueKey('game_detail_desktop_${widget.gameId}_$_refreshCounter'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: GameDetailContent( // 传递数据给 Content
            game: game,
            initialCollectionStatus: _collectionStatus, // <--- 传递状态
            onCollectionChanged: _handleCollectionChanged, // <--- 传递回调
            onNavigate: _handleNavigate,
            navigationInfo: _navigationInfo,        // <--- 加上这一行
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
      return Scaffold(appBar: AppBar(title: Text('错误')), body: Center(child: Text('无效的游戏 ID')));
    }

    // --- Loading / Error / Content 构建逻辑 ---
    if (_isLoading && _game == null) { // 首次加载时全屏 Loading
      return LoadingWidget.fullScreen(message: '加载中...');
    }

    if (_error != null && _game == null) { // 首次加载失败时全屏 Error
      if (_error == 'not_found') { return NotFoundErrorWidget(onBack: () => Navigator.of(context).pop()); }
      if (_error == 'network_error') { return NetworkErrorWidget(onRetry: () => _loadGameDetailsWithStatus(forceRefresh: true)); }
      if (_error == 'pending_approval') { return Scaffold(appBar: AppBar(title: Text('游戏详情'), leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => NavigationUtils.pop(context),),), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.pending_actions, size: 64, color: Colors.orange), SizedBox(height: 16), Text('游戏正在审核中', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),), SizedBox(height: 8), Text('该游戏正在等待管理员审核，审核通过后将可以查看。', textAlign: TextAlign.center, style: TextStyle(fontSize: 16),), SizedBox(height: 24), ElevatedButton(onPressed: () => NavigationUtils.pop(context), child: Text('返回'),), ],),),); }
      return CustomErrorWidget(errorMessage: _error, onRetry: () => _loadGameDetailsWithStatus(forceRefresh: true));
    }

    // 如果 _game 为 null 但不在加载也没错误，显示错误
    if (_game == null) {
      return Scaffold(appBar: AppBar(title: Text('错误')), body: Center(child: Text('无法加载游戏数据')));
    }

    // --- 正常渲染游戏内容 ---
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    Widget bodyContent = isDesktop ? _buildDesktopLayout(_game!) : _buildMobileLayout(_game!);

    // --- 处理刷新时的 Loading 状态 (叠加 Loading 指示器) ---
    if (_isLoading && _game != null) { // 正在刷新且有旧数据
      bodyContent = Stack(
        children: [
          IgnorePointer(child: Opacity(opacity: 0.5, child: bodyContent)),
          Positioned.fill(
              child: Container(
                // 使用半透明颜色，避免完全遮挡
                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3),
                  child: Center(child: CircularProgressIndicator())
              )
          ),
        ],
      );
    }
    // --- ---

    return bodyContent; // 返回最终构建的 Widget
  }
}
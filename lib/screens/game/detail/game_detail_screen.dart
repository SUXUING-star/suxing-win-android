// lib/screens/game/detail/game_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_sliver_app_bar.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import '../../../widgets/components/screen/game/button/like_button.dart';
import '../../../widgets/components/screen/game/game_detail_content.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';
import '../../../widgets/ui/common/error_widget.dart';
import '../../../widgets/ui/common/loading_widget.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../routes/app_routes.dart';

class GameDetailScreen extends StatefulWidget {
  final String? gameId;

  const GameDetailScreen({Key? key, this.gameId}) : super(key: key);

  @override
  _GameDetailScreenState createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final GameService _gameService = GameService();
  Game? _game;
  String? _error;
  bool _isLoading = false;
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    if (widget.gameId != null) {
      _loadGameDetails();
      _incrementViewCount();
      _addToHistory();
    } else {
      setState(() {
        _error = '无效的游戏ID';
      });
    }
  }

  void _addToHistory() {
    if (widget.gameId != null) {
      _gameService.addToGameHistory(widget.gameId!);
    }
  }

  Future<void> _loadGameDetails() async {
    if (widget.gameId == null) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final game = await _gameService.getGameById(widget.gameId!);
      if (game == null) {
        throw 'not_found';
      }

      setState(() {
        _game = game;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;

        // 增加新的错误类型处理
        if (e.toString().contains('game_pending_approval')) {
          _error = 'pending_approval';
        } else if (e == 'not_found') {
          _error = 'not_found';
        } else {
          _error = e.toString();
        }
      });
    }
  }

  Future<void> _refreshGameDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      await _loadGameDetails();
      _incrementViewCount();
      _addToHistory();
    } finally {
      setState(() {
        _isLoading = false;
        _refreshCounter++;
      });
    }
  }

  void _incrementViewCount() {
    if (widget.gameId != null) {
      _gameService.incrementGameView(widget.gameId!);
    }
  }

  void _handleLikeChanged() {
    _refreshGameDetails();
  }

  void _handleCommentAdded() {
    _refreshGameDetails();
  }

  // 处理导航
  void _handleNavigate(String gameId) {
    NavigationUtils.pushNamed(
      context,
      AppRoutes.gameDetail,
      arguments: gameId,
    );
  }

  // 检查当前用户是否有权限编辑游戏
  bool _canEditGame(BuildContext context, Game game) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // 允许管理员或游戏创建者进行编辑
    return authProvider.isAdmin ||
        (authProvider.isLoggedIn && authProvider.currentUser?.id == game.authorId);
  }

  // 处理编辑按钮点击
  void _handleEditPressed(BuildContext context, Game game) async {
    // 使用 AppRoutes 常量
    final result = await NavigationUtils.pushNamed(
      context,
      AppRoutes.editGame,
      arguments: game,
    );

    // 如果返回结果为 true，表示游戏已更新，刷新页面
    if (result == true) {
      _refreshGameDetails();
    }
  }

  Widget _buildMobileLayout(Game game) {
    final bool canEdit = _canEditGame(context, game);

    final flexibleSpaceBackground = Stack(
      fit: StackFit.expand,
      children: [
        // 使用 SafeCachedImage 替换 Image.network
        SafeCachedImage(
          imageUrl: game.coverImage,
          fit: BoxFit.cover,
          // SafeCachedImage 内部处理了 placeholder 和 errorWidget
          // 不需要在这里提供 loadingBuilder 和 errorBuilder
          // 让 StackFit.expand 控制大小，不需要指定 width/height
        ),
        // 保持底部的渐变遮罩，让标题文字更清晰
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, // 从顶部开始
              end: Alignment.bottomCenter, // 到底部结束
              stops: [0.5, 1.0], // 渐变范围，可以调整，比如从中间 50% 开始变黑
              colors: [
                Colors.transparent, // 上半部分透明
                Colors.black87,     // 下半部分黑色，透明度 87%
              ],
            ),
          ),
        ),
        // 再加一个顶部的轻微渐变，让顶部Action按钮在亮色背景下也可见
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: [0.8, 1.0], // 只在最顶部一点区域生效
              colors: [
                Colors.transparent,
                Colors.black38, // 顶部加一点点暗色
              ],
            ),
          ),
        ),
      ],
    );
    return Scaffold(
      // 注意：如果 Scaffold 有背景色，且 SliverAppBar 收起时背景色有透明度，
      // 可能会透出 Scaffold 的颜色。这里我们给 SliverAppBar 设置了实色背景，应该没问题了。
      body: RefreshIndicator(
        onRefresh: _refreshGameDetails,
        child: CustomScrollView(
          key: ValueKey('game_detail_${_refreshCounter}'),
          slivers: [
            CustomSliverAppBar(
              titleText: game.title,
              expandedHeight: 300,

              pinned: true,
              flexibleSpaceBackground: flexibleSpaceBackground, // 传入包含 SafeCachedImage 的 Stack
              // collapsedBackgroundColor: Color(0xFF4E9DE3), // 可以省略，使用 CustomSliverAppBar 的默认值
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white), // 确保图标白色
                  onPressed: () { /* 分享 */ },
                  tooltip: '分享',
                ),
              ],
              // leading: 会自动添加返回按钮（如果路由栈能 pop）
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 80), // 为 FAB 留出空间
              sliver: SliverToBoxAdapter(
                child: GameDetailContent(
                  game: game,
                  onNavigate: _handleNavigate,
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
            if (canEdit) // 只有当用户有权限时才显示编辑按钮
              FloatingActionButton(
                heroTag: 'editButton',
                onPressed: () => _handleEditPressed(context, game),
                child: Icon(Icons.edit),
                backgroundColor: Colors.white,
              ),
            const SizedBox(width: 16.0),
            LikeButton(
              game: game,
              gameService: _gameService,
              onLikeChanged: _handleLikeChanged,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildDesktopLayout(Game game) {
    final bool canEdit = _canEditGame(context, game);

    return Scaffold(
      appBar: CustomAppBar(
        title: game.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 实现分享功能
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: LikeButton(
              game: game,
              gameService: _gameService,
              onLikeChanged: _handleLikeChanged,
            ),
          ),
          if (canEdit) // 只有当用户有权限时才显示编辑按钮
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _handleEditPressed(context, game),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        key: ValueKey('game_detail_content_${_refreshCounter}'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: GameDetailContent(
            game: game,
            onNavigate: _handleNavigate,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gameId == null) {
      return const CustomErrorWidget(errorMessage: '无效的游戏ID');
    }

    if (_isLoading) {
      return LoadingWidget.fullScreen(message: '加载中...');
    }


    if (_error != null) {
      if (_error == 'not_found') {
        return NotFoundErrorWidget(onBack: _loadGameDetails);
      } else if (_error == 'network_error') {
        return NetworkErrorWidget(onRetry: _loadGameDetails);
      } else if (_error == 'pending_approval') {
        // 新增：游戏待审核的友好提示
        return Scaffold(
          appBar: AppBar(
            title: Text('游戏详情'),
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
                ElevatedButton(
                  onPressed: () => NavigationUtils.pop(context),
                  child: Text('返回'),
                ),
              ],
            ),
          ),
        );
      } else {
        return CustomErrorWidget(errorMessage: _error, onRetry: _loadGameDetails);
      }
    }

    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return isDesktop ? _buildDesktopLayout(_game!) : _buildMobileLayout(_game!);
  }
}
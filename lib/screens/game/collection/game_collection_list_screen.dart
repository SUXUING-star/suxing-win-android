// lib/screens/collection/game_collection_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/game/game_collection.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/main/game/collection/game_collection_service.dart';
import '../../../utils/device/device_utils.dart';
import '../../../utils/load/loading_route_observer.dart';
import '../../../widgets/common/appbar/custom_app_bar.dart';
import '../../../widgets/components/screen/game/card/game_card.dart';

class GameCollectionListScreen extends StatefulWidget {
  final String collectionType;
  final String title;

  const GameCollectionListScreen({
    Key? key,
    required this.collectionType,
    required this.title,
  }) : super(key: key);

  @override
  _GameCollectionListScreenState createState() => _GameCollectionListScreenState();
}

class _GameCollectionListScreenState extends State<GameCollectionListScreen> {
  final GameCollectionService _collectionService = GameCollectionService();
  List<GameWithCollection> _games = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDisposed = false; // 添加标志位追踪组件状态

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 使用 mounted 检查确保组件仍在树中
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;  // 再次检查，因为回调可能在组件销毁后执行

      final loadingObserver = Navigator.of(context)
          .widget.observers
          .whereType<LoadingRouteObserver>()
          .first;

      loadingObserver.showLoading();

      // 加载收藏游戏列表
      _loadCollectionGames().then((_) {
        if (!mounted) return;  // 确保组件仍然存在
        loadingObserver.hideLoading();
      });
    });
  }

  @override
  void dispose() {
    _isDisposed = true; // 标记组件已销毁
    super.dispose();
  }

  Future<void> _loadCollectionGames() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 检查用户是否已登录
      if (!authProvider.isLoggedIn) {
        setState(() {
          _errorMessage = '请先登录后再查看收藏';
          _isLoading = false;
        });
        return;
      }

      // 获取游戏列表 - 修改这里，使用常量值而不是常量名
      String status;

      // 根据路由类型转换为正确的状态值
      switch (widget.collectionType) {
        case 'wantToPlay':
          status = GameCollectionStatus.wantToPlay; // 使用常量值 'want_to_play'
          break;
        case 'playing':
          status = GameCollectionStatus.playing; // 使用常量值 'playing'
          break;
        case 'played':
          status = GameCollectionStatus.played; // 使用常量值 'played'
          break;
        case 'all':
          status = 'all';
          break;
        default:
          status = widget.collectionType;
      }

      print('正在加载收藏游戏，状态: $status'); // 调试日志

      final games = await _collectionService.getUserGamesByStatus(status);

      if (mounted) {
        setState(() {
          _games = games;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Load collection games error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '加载收藏游戏失败：$e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      await _loadCollectionGames();
    } finally {
      if (mounted) {  // 确保在显示/隐藏加载指示器时组件仍然存在
        loadingObserver.hideLoading();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildError(_errorMessage!);
    }

    if (_isLoading) {
      return _buildLoading();
    }

    if (_games.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        childAspectRatio: DeviceUtils.calculateCardRatio(context),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _games.length,
      itemBuilder: (context, index) {
        final item = _games[index];
        return GameCard(
          game: item.game,
        );
      },
    );
  }

  Widget _buildCollectionStatus(GameCollectionItem collection) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (collection.status) {
      case GameCollectionStatus.wantToPlay:
        statusIcon = Icons.star_border;
        statusColor = Colors.blue;
        statusText = '想玩';
        break;
      case GameCollectionStatus.playing:
        statusIcon = Icons.videogame_asset;
        statusColor = Colors.green;
        statusText = '在玩';
        break;
      case GameCollectionStatus.played:
        statusIcon = Icons.check_circle;
        statusColor = Colors.purple;
        statusText = '玩过';
        break;
      default:
        statusIcon = Icons.bookmark;
        statusColor = Colors.grey;
        statusText = '已收藏';
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 16),
        SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (collection.rating != null) ...[
          SizedBox(width: 8),
          Icon(Icons.star, color: Colors.amber, size: 16),
          SizedBox(width: 4),
          Text(
            collection.rating!.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: Text('重试'),
          ),
          if (message.contains('请先登录'))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: Text('去登录'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    String message;
    IconData icon;

    switch (widget.collectionType) {
      case 'wantToPlay':
        message = '还没有想玩的游戏';
        icon = Icons.star_border;
        break;
      case 'playing':
        message = '还没有在玩的游戏';
        icon = Icons.videogame_asset;
        break;
      case 'played':
        message = '还没有玩过的游戏';
        icon = Icons.check_circle;
        break;
      default:
        message = '还没有收藏任何游戏';
        icon = Icons.collections_bookmark;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.gamesList);
            },
            child: Text('发现游戏'),
          ),
        ],
      ),
    );
  }
}
// lib/screens/hot_games_screen.dart
import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../services/game_service.dart';
import '../../widgets/game/game_card.dart';
import '../../utils/loading_route_observer.dart';

class HotGamesScreen extends StatefulWidget {
  @override
  _HotGamesScreenState createState() => _HotGamesScreenState();
}

class _HotGamesScreenState extends State<HotGamesScreen> {
  final GameService _gameService = GameService();
  List<Game>? _games;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 获取 LoadingRouteObserver 实例
      final loadingObserver = Navigator.of(context)
          .widget.observers
          .whereType<LoadingRouteObserver>()
          .first;

      // 显示加载动画
      loadingObserver.showLoading();

      // 加载数据
      _loadGames().then((_) {
        // 隐藏加载动画
        loadingObserver.hideLoading();
      });
    });
  }

  Future<void> _loadGames() async {
    try {
      final games = await _gameService.getHotGames().first;
      setState(() {
        _games = games;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败：${e.toString()}';
        _games = [];
      });
    }
  }

  Future<void> _refreshData() async {
    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      await _loadGames();
    } finally {
      loadingObserver.hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('热门游戏'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_games == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_games!.isEmpty) {
      return Center(child: Text('暂无热门游戏'));
    }

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _games!.length,
      itemBuilder: (context, index) {
        return GameCard(game: _games![index]);
      },
    );
  }
}
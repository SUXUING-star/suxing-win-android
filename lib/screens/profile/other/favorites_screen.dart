// lib/screens/profile/favorites_screen.dart
import 'package:flutter/material.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/load/loading_route_observer.dart';
import '../../../widgets/common/custom_app_bar.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final GameService _gameService = GameService();
  List<Game>? _favoriteGames;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loadingObserver = Navigator.of(context)
          .widget
          .observers
          .whereType<LoadingRouteObserver>()
          .first;

      loadingObserver.showLoading();

      _loadFavoriteGames().then((_) {
        loadingObserver.hideLoading();
      });
    });
  }

  Future<void> _loadFavoriteGames() async {
    try {
      final favoriteIds = await _gameService.getUserFavorites().first;

      if (favoriteIds.isEmpty) {
        setState(() {
          _favoriteGames = [];
        });
        return;
      }

      final games = await _gameService.getGames().first;
      final favoriteGames =
          games.where((game) => favoriteIds.contains(game.id)).toList();

      setState(() {
        _favoriteGames = favoriteGames;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _favoriteGames = [];
      });
    }
  }

  Future<void> _refreshFavorites() async {
    final loadingObserver = Navigator.of(context)
        .widget
        .observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      await _loadFavoriteGames();
    } finally {
      loadingObserver.hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '我的收藏'),
      body: RefreshIndicator(
        onRefresh: _refreshFavorites,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFavoriteGames,
              child: Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (_favoriteGames == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (_favoriteGames!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无收藏的游戏'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _favoriteGames!.length,
      itemBuilder: (context, index) {
        final game = _favoriteGames![index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(game.coverImage),
          ),
          title: Text(game.title),
          subtitle: Text(game.summary),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.favorite, color: Colors.red),
                onPressed: () => _toggleLike(game.id),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.gameDetail,
                    arguments: game,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleLike(String gameId) async {
    try {
      await _gameService.toggleLike(gameId);
      await _loadFavoriteGames();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('取消收藏失败: $e')),
      );
    }
  }
}

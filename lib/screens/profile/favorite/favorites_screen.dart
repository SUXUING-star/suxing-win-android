// lib/screens/profile/favorites_screen.dart
import 'package:flutter/material.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import '../../../utils/load/loading_route_observer.dart';
import '../../../widgets/common/appbar/custom_app_bar.dart';
import '../../../widgets/components/screen/profile/favorite/responsive_favorites_layout.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final GameService _gameService = GameService();
  List<Game>? _favoriteGames;
  String? _error;
  bool _isLoading = true;

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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 使用优化方法直接获取完整的收藏游戏信息
      final favoriteGames = await _gameService.getUserFavoriteGames();

      if (mounted) {
        setState(() {
          _favoriteGames = favoriteGames;
          _error = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载失败: $e';
          _favoriteGames = [];
          _isLoading = false;
        });
      }
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

  // 处理游戏收藏状态切换
  Future<void> _toggleFavorite(String gameId) async {
    try {
      await _gameService.toggleLike(gameId);
      await _loadFavoriteGames();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('取消收藏失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '我的收藏'),
      body: ResponsiveFavoritesLayout(
        games: _favoriteGames ?? [],
        isLoading: _isLoading,
        error: _error,
        onRefresh: _refreshFavorites,
        onToggleFavorite: _toggleFavorite,
      ),
    );
  }
}
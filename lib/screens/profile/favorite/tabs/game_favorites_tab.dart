// lib/screens/profile/tabs/game_favorites_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../../../models/game/game.dart';
import '../../../../services/main/game/game_service.dart';
import '../../../../widgets/components/screen/profile/favorite/responsive_favorites_layout.dart';

class GameFavoritesTab extends StatefulWidget {
  // 静态刷新方法，供主页面调用
  static void refreshGameData() {
    // 这里使用一个全局键来访问状态
    _gameTabKey.currentState?.refreshGames();
  }

  static final GlobalKey<_GameFavoritesTabState> _gameTabKey =
      GlobalKey<_GameFavoritesTabState>();

  GameFavoritesTab() : super(key: _gameTabKey);

  @override
  _GameFavoritesTabState createState() => _GameFavoritesTabState();
}

class _GameFavoritesTabState extends State<GameFavoritesTab>
    with AutomaticKeepAliveClientMixin {
  List<Game>? _favoriteGames;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteGames();
  }

  Future<void> _loadFavoriteGames() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gameService = context.read<GameService>();
      final games = await gameService.getUserLikeGames();

      if (mounted) {
        setState(() {
          _favoriteGames = games;
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

  Future<void> refreshGames() async {
    return _loadFavoriteGames();
  }

  Future<void> _toggleGameFavorite(String gameId) async {
    try {
      final gameService = context.read<GameService>();
      await gameService.toggleLike(gameId);
      await _loadFavoriteGames();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, '取消收藏失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ResponsiveFavoritesLayout(
      games: _favoriteGames ?? [],
      isLoading: _isLoading,
      error: _error,
      onRefresh: refreshGames,
      onToggleFavorite: _toggleGameFavorite,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

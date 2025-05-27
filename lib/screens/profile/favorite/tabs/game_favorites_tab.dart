// lib/screens/profile/favorite/tabs/game_favorites_tab.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/components/screen/profile/favorite/responsive_favorites_layout.dart';

class GameFavoritesTab extends StatefulWidget {
  // 静态刷新方法，供主页面调用
  static void refreshGameData() {
    // 这里使用一个全局键来访问状态
    _gameTabKey.currentState?.refreshGames();
  }

  static final GlobalKey<_GameFavoritesTabState> _gameTabKey =
      GlobalKey<_GameFavoritesTabState>();

  final User? currentUser;
  final GameService gameService;
  GameFavoritesTab(
    this.currentUser,
    this.gameService,
  ) : super(key: _gameTabKey);

  @override
  _GameFavoritesTabState createState() => _GameFavoritesTabState();
}

class _GameFavoritesTabState extends State<GameFavoritesTab>
    with AutomaticKeepAliveClientMixin {
  List<Game>? _favoriteGames;
  String? _error;
  bool _isLoading = false;
  bool _hasInitializedDependencies = false;
  late final GameService _gameService;
  User? _currentUser;

  @override
  void initState() {
    _currentUser = widget.currentUser;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _gameService = widget.gameService;
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _loadFavoriteGames();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameFavoritesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser != widget.currentUser ||
        _currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
  }

  Future<void> _loadFavoriteGames() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final games = await _gameService.getUserLikeGames();

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
      await _gameService.toggleLike(gameId, false);
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

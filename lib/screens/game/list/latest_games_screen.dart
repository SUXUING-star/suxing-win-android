// lib/screens/game/list/latest_games_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'common_game_list_screen.dart';

class LatestGamesScreen extends StatefulWidget {
  final GameService gameService;
  final AuthProvider authProvider;
  final WindowStateProvider windowStateProvider;
  const LatestGamesScreen({
    super.key,
    required this.gameService,
    required this.authProvider,
    required this.windowStateProvider,
  });

  @override
  _LatestGamesScreenState createState() => _LatestGamesScreenState();
}

class _LatestGamesScreenState extends State<LatestGamesScreen> {
  List<Game> _latestGames = [];
  bool _isLoading = true; // 初始为 true
  String? _error;
  bool _hasInitializedDependencies = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _fetchLatestGames(); // 初始化时开始加载数据
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchLatestGames() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      // if (_latestGames.isNotEmpty) _latestGames = []; // 刷新时不清除旧数据
    });

    try {
      final games = await widget.gameService.getLatestGames(); // 直接 await 获取数据
      if (!mounted) return;
      setState(() {
        _latestGames = games;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '加载最新游戏失败: $e';
        _isLoading = false;
        _latestGames = []; // 出错时清空
      });
    }
  }

  // *** 修改: 下拉刷新直接调用加载方法 ***
  Future<void> _handleRefresh() async {
    await _fetchLatestGames(); // 重新加载数据
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream,
      initialData: widget.authProvider.currentUser,
      builder: (context, authSnapshot) {
        final User? currentUser = authSnapshot.data;
        return CommonGameListScreen(
          key: ValueKey(
              'latest_games_${_latestGames.length}_$_isLoading$_error'),
          title: '最新发布',
          currentUser: currentUser,
          games: _latestGames,
          isLoading: _isLoading,
          error: _error,
          onRefreshTriggered: _handleRefresh,
          windowStateProvider: widget.windowStateProvider,
          onDeleteGameAction: null,
          emptyStateMessage: '暂无最新游戏',
          emptyStateIcon:
              Icon(Icons.new_releases, size: 48, color: Colors.grey),
          useScaffold: true,
          showAddButton: false,
          showSortOptions: false,
        );
      },
    );
  }
}

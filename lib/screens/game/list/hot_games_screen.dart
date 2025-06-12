// lib/screens/game/list/hot_games_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'common_game_list_screen.dart';

class HotGamesScreen extends StatefulWidget {
  final GameService gameService;
  final AuthProvider authProvider;
  final WindowStateProvider windowStateProvider;
  const HotGamesScreen({
    super.key,
    required this.authProvider,
    required this.gameService,
    required this.windowStateProvider,
  });

  @override
  _HotGamesScreenState createState() => _HotGamesScreenState();
}

class _HotGamesScreenState extends State<HotGamesScreen> {
  List<Game> _hotGames = [];
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
      _fetchHotGames(); // 初始化时开始加载数据
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 加载数据并更新状态
  Future<void> _fetchHotGames() async {
    if (!mounted) return; // 异步操作前检查 mounted

    setState(() {
      _isLoading = true; // 开始加载，显示 Loading
      _error = null; // 清除旧错误
    });

    try {
      final games = await widget.gameService.getHotGames();
      if (!mounted) return; // 异步操作后再次检查
      setState(() {
        _hotGames = games; // 更新数据
        _isLoading = false; // 加载完成
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '加载热门游戏失败: $e'; // 设置错误信息
        _isLoading = false; // 加载完成（但有错误）
        _hotGames = []; // 出错时清空列表
      });
    }
  }

  // *** 修改: 下拉刷新直接调用加载方法 ***
  Future<void> _handleRefresh() async {
    await _fetchHotGames(); // 重新加载数据
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authProvider.currentUserStream,
      initialData: widget.authProvider.currentUser,
      builder: (context, authSnapshot) {
        final User? currentUser = authSnapshot.data;
        return CommonGameListScreen(
          key: ValueKey('hot_games_${_hotGames.length}_$_isLoading$_error'),
          title: '热门游戏',
          currentUser: currentUser,
          games: _hotGames,
          isLoading: _isLoading,
          error: _error,
          onRefreshTriggered: _handleRefresh,
          windowStateProvider: widget.windowStateProvider,
          // 传递刷新回调
          onDeleteGameAction: null,
          emptyStateMessage: '暂无热门游戏',
          emptyStateIcon:
              Icon(Icons.local_fire_department, size: 48, color: Colors.grey),
          useScaffold: true,
          showAddButton: false,
          showSortOptions: false,
        );
      },
    );
  }
}

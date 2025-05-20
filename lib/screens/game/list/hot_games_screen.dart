import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import 'common_game_list_screen.dart'; // 引入纯净版

class HotGamesScreen extends StatefulWidget {
  const HotGamesScreen({super.key});

  @override
  _HotGamesScreenState createState() => _HotGamesScreenState();
}

class _HotGamesScreenState extends State<HotGamesScreen> {
  // *** 修改: 管理实际数据和状态 ***
  List<Game> _hotGames = [];
  bool _isLoading = true; // 初始为 true
  String? _error;
  late final GameService _gameService;
  bool _hasInitializedDependencies = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _gameService = context.read<GameService>();
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
      // 刷新时不清除旧数据，让 Loading 覆盖
      // if (_hotGames.isNotEmpty) _hotGames = [];
    });

    try {
      final games = await _gameService.getHotGames(); // 直接 await 获取数据
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
    final authProvider = context.watch<AuthProvider>();
    return CommonGameListScreen(
      key: ValueKey(
          'hot_games_${_hotGames.length}_$_isLoading$_error'), // Key 可以更精细反映状态
      title: '热门游戏',
      currentUser: authProvider.currentUser,
      games: _hotGames,
      isLoading: _isLoading,
      error: _error,
      onRefreshTriggered: _handleRefresh, // 传递刷新回调
      onDeleteGameAction: null, // 这些页面通常不需要删除操作
      emptyStateMessage: '暂无热门游戏',
      emptyStateIcon:
          Icon(Icons.local_fire_department, size: 48, color: Colors.grey),
      useScaffold: true,
      showAddButton: false,
      showSortOptions: false,
      // 移除了 showTagSelection, showPanelToggles
    );
  }
}

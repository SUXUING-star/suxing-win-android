import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import 'common_game_list_screen.dart'; // 引入新的 Base

class LatestGamesScreen extends StatefulWidget {
  const LatestGamesScreen({super.key});

  @override
  _LatestGamesScreenState createState() => _LatestGamesScreenState();
}

class _LatestGamesScreenState extends State<LatestGamesScreen> {
  // *** 用于触发 FutureBuilder 重建 ***
  late Future<List<Game>> _latestGamesFuture;

  @override
  void initState() {
    super.initState();
    _latestGamesFuture = _loadLatestGames(); // 初始化 Future
  }

  // 加载最新游戏数据 (返回 Future)
  Future<List<Game>> _loadLatestGames() async {
    try {
      // 使用 .first 获取 Stream 的第一个结果
      final gameService = context.read<GameService>();
      return await gameService.getLatestGames();
    } catch (e) {
      //print("Error loading latest games: $e");
      // 向上抛出异常让 FutureBuilder 处理
      throw Exception('Failed to load latest games: $e');
      // 或返回空列表
      // return [];
    }
  }

  // 下拉刷新触发的逻辑
  Future<void> _handleRefresh() async {
    // 通过 setState 改变 Future 对象来触发 FutureBuilder 重建
    setState(() {
      _latestGamesFuture = _loadLatestGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonGameListScreen(
      key: ValueKey('latest_games'), // 可以用 Key 来辅助刷新
      title: '最新发布',
      gamesFuture: _latestGamesFuture,
      // *** 传递下拉刷新回调 ***
      onRefreshTriggered: _handleRefresh,
      // --- 其他参数 ---
      onDeleteGameAction: (gameId) async { /* No action needed */ },
      // onEditGameAction: (game) async { /* No action needed */ },
      emptyStateMessage: '暂无最新游戏',
      emptyStateIcon: Icon(Icons.new_releases, size: 48, color: Colors.grey), // 不加 const
      showTagSelection: false,
      showPanelToggles: false,
      useScaffold: true, // 通常需要自己的 Scaffold
      showAddButton: false,
      showSortOptions: false,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import 'common_game_list_screen.dart'; // 引入新的 Base

class HotGamesScreen extends StatefulWidget {
  const HotGamesScreen({super.key});

  @override
  _HotGamesScreenState createState() => _HotGamesScreenState();
}

class _HotGamesScreenState extends State<HotGamesScreen> {
  // *** 用于触发 FutureBuilder 重建 ***
  late Future<List<Game>> _hotGamesFuture;

  @override
  void initState() {
    super.initState();
    _hotGamesFuture = _loadHotGames(); // 初始化 Future
  }

  // 加载热门游戏数据 (返回 Future)
  Future<List<Game>> _loadHotGames() async {
    try {
      // .first 仍然适用，因为 getHotGames 是 Stream，我们取第一个结果
      final gameService = context.read<GameService>();
      return await gameService.getHotGames();
    } catch (e) {
      //print("Error loading hot games: $e");
      // 可以选择向上抛出异常让 FutureBuilder 处理
      throw Exception('Failed to load hot games: $e');
      // 或者返回空列表，让 FutureBuilder 显示空状态
      // return [];
    }
  }

  // 下拉刷新触发的逻辑
  Future<void> _handleRefresh() async {
    // 通过 setState 改变 Future 对象来触发 FutureBuilder 重建
    setState(() {
      _hotGamesFuture = _loadHotGames();
    });
    // FutureBuilder 会自动处理新的 Future
  }


  @override
  Widget build(BuildContext context) {
    return CommonGameListScreen(
      key: ValueKey('hot_games'), // 可以用 Key 来辅助刷新
      title: '热门游戏',
      // *** 传递 Future ***
      gamesFuture: _hotGamesFuture,
      onRefreshTriggered: _handleRefresh,
      onDeleteGameAction: (gameId) async { /* No action needed */ },
      emptyStateMessage: '暂无热门游戏',
      emptyStateIcon: Icon(Icons.local_fire_department, size: 48, color: Colors.grey), // 不加 const
      showTagSelection: false,
      showPanelToggles: false,
      useScaffold: true, // HotGamesScreen 可能需要自己的 Scaffold
      showAddButton: false,
      showSortOptions: false,
    );
  }
}
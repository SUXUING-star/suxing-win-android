import 'package:flutter/material.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import 'base_game_list_screen.dart';

class HotGamesScreen extends StatefulWidget {
  @override
  _HotGamesScreenState createState() => _HotGamesScreenState();
}

class _HotGamesScreenState extends State<HotGamesScreen> {
  final GameService _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return BaseGameListScreen(
      title: '热门游戏',
      loadGamesFunction: _loadGames,
      emptyStateMessage: '暂无热门游戏',
      emptyStateIcon: Icon(Icons.local_fire_department, size: 48, color: Colors.grey),
      // 不使用标签选择和面板显示
      showTagSelection: false,
      showPanelToggles: false,
    );
  }

  Future<List<Game>> _loadGames() async {
    // 使用优化的getHotGames方法，利用Redis缓存
    return await _gameService.getHotGames().first;
  }
}
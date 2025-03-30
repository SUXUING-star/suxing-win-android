import 'package:flutter/material.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import 'base_game_list_screen.dart';

class LatestGamesScreen extends StatefulWidget {
  @override
  _LatestGamesScreenState createState() => _LatestGamesScreenState();
}

class _LatestGamesScreenState extends State<LatestGamesScreen> {
  final GameService _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return BaseGameListScreen(
      title: '最新发布',
      loadGamesFunction: _loadGames,
      emptyStateMessage: '暂无最新游戏',
      emptyStateIcon: Icon(Icons.new_releases, size: 48, color: Colors.grey),
      // 不使用标签选择和面板显示
      showTagSelection: false,
      showPanelToggles: false,
    );
  }

  Future<List<Game>> _loadGames(String? tag) async {
    // 最新游戏可能不需要标签筛选，但仍需要保持函数签名一致
    return await _gameService.getLatestGames().first;
  }
}
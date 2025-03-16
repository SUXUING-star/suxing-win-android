// lib/screens/game/games_list_screen.dart
import 'package:flutter/material.dart';
import '../../../models/game/game.dart';
import '../../../services/main/game/game_service.dart';
import 'base_game_list_screen.dart';

class GamesListScreen extends StatefulWidget {
  final String? selectedTag;

  const GamesListScreen({
    Key? key,
    this.selectedTag,
  }) : super(key: key);

  @override
  _GamesListScreenState createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen> {
  final GameService _gameService = GameService();

  // 分页相关参数
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalPages = 1;
  String _currentSortBy = 'createTime';
  bool _isDescending = true;

  @override
  Widget build(BuildContext context) {
    return BaseGameListScreen(
      title: '游戏列表',
      loadGamesFunction: _loadGames,
      refreshFunction: _refreshData,
      showTagSelection: true,
      selectedTag: widget.selectedTag,
      showSortOptions: true,
      showAddButton: true,
      emptyStateMessage: '暂无游戏数据',
      enablePagination: true,
      showPanelToggles: true,
    );
  }

  Future<List<Game>> _loadGames() async {
    Map<String, dynamic> result;

    final selectedTag = widget.selectedTag;
    if (selectedTag != null) {
      result = await _gameService.getGamesByTagWithInfo(
        tag: selectedTag,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _currentSortBy,
        descending: _isDescending,
      );
    } else {
      result = await _gameService.getGamesPaginatedWithInfo(
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _currentSortBy,
        descending: _isDescending,
      );
    }

    final games = result['games'] as List<Game>;
    final pagination = result['pagination'] as Map<String, dynamic>;

    _totalPages = pagination['totalPages'] as int? ?? 1;

    return games;
  }

  Future<void> _refreshData() async {
    _currentPage = 1;
    // BaseGameListScreen 会处理剩余的刷新流程
  }

  void _updateSorting(String sortBy, bool descending) {
    _currentSortBy = sortBy;
    _isDescending = descending;
    _currentPage = 1; // 重置到第一页
  }
}
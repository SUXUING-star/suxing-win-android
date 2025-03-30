// lib/screens/game/games_list_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
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
  String? _currentTag; // 当前选中的标签


  @override
  void initState() {
    super.initState();
    _currentTag = widget.selectedTag; // 初始化当前标签
  }


  @override
  Widget build(BuildContext context) {
    return BaseGameListScreen(
      title: '游戏',
      loadGamesFunction: (tag) => _loadGames(tag),
      refreshFunction: _refreshData,
      showTagSelection: true,
      selectedTag: _currentTag, // 使用本地状态管理当前标签
      showSortOptions: true,
      showAddButton: true,
      emptyStateMessage: '暂无游戏数据',
      enablePagination: true,
      showPanelToggles: true,

      // 使用基类提供的AppBar功能
      useScaffold: true,
      showAddButtonInAppBar: true,
      showMySubmissionsButton: true,
      onFilterPressed: (context) => _showFilterDialog(context),
      onMySubmissionsPressed: () {
        NavigationUtils.pushNamed(context, AppRoutes.myGames);
      },
      onAddPressed: () {
        NavigationUtils.pushNamed(context, AppRoutes.addGame);
      },
    );
  }


  // 重载这个方法，根据是否有标签选择，调用不同的服务方法
  Future<List<Game>> _loadGames(String? tag) async {
    // 使用传入的标签参数而不是本地状态
    Map<String, dynamic> result;

    if (tag != null) {
      // 使用标签筛选游戏
      result = await _gameService.getGamesByTagWithInfo(
        tag: tag,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _currentSortBy,
        descending: _isDescending,
      );
    } else {
      // 获取所有游戏
      result = await _gameService.getGamesPaginatedWithInfo(
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _currentSortBy,
        descending: _isDescending,
      );
    }

    // 更新当前标签状态，保持同步
    setState(() {
      _currentTag = tag;
    });

    final games = result['games'] as List<Game>;
    final pagination = result['pagination'] as Map<String, dynamic>;

    _totalPages = pagination['totalPages'] as int? ?? 1;

    return games;
  }


  Future<void> _refreshData() async {
    _currentPage = 1;
    // BaseGameListScreen 会处理剩余的刷新流程
  }

  // 排序对话框
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('排序方式'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortOption('创建时间', 'createTime'),
              _buildSortOption('浏览次数', 'viewCount'),
              _buildSortOption('喜欢数量', 'likeCount'),
              _buildSortOption('评分', 'rating'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => NavigationUtils.pop(context),
              child: Text('取消'),
            ),
          ],
        );
      },
    );
  }

  // 构建排序选项
  Widget _buildSortOption(String title, String sortField) {
    final isSelected = _currentSortBy == sortField;

    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_upward,
              color: isSelected && !_isDescending ? Colors.blue : Colors.grey,
            ),
            onPressed: () {
              NavigationUtils.pop(context);
              setState(() {
                _currentSortBy = sortField;
                _isDescending = false;
              });
              _refreshData();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_downward,
              color: isSelected && _isDescending ? Colors.blue : Colors.grey,
            ),
            onPressed: () {
              NavigationUtils.pop(context);
              setState(() {
                _currentSortBy = sortField;
                _isDescending = true;
              });
              _refreshData();
            },
          ),
        ],
      ),
      onTap: () {
        NavigationUtils.pop(context);
        setState(() {
          _currentSortBy = sortField;
        });
        _refreshData();
      },
    );
  }
}
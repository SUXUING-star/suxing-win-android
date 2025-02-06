import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../services/game_service.dart';
import '../../utils/admin_check.dart';
import '../../widgets/game/game_card.dart';
import '../../utils/loading_route_observer.dart';
import '../../widgets/common/custom_app_bar.dart';

class GamesListScreen extends StatefulWidget {
  @override
  _GamesListScreenState createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen> {
  final GameService _gameService = GameService();
  List<Game> _games = [];
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalPages = 1;
  bool _isLoading = false;
  String _currentSortBy = 'createTime';
  bool _isDescending = true;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loadingObserver = Navigator.of(context)
          .widget.observers
          .whereType<LoadingRouteObserver>()
          .first;

      loadingObserver.showLoading();

      _loadGames().then((_) {
        loadingObserver.hideLoading();
      });
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100
        && !_isLoading
        && _currentPage < _totalPages) {
      _loadMoreGames();
    }
  }

  Future<void> _loadGames({bool initialLoad = true}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (initialLoad) {
        _currentPage = 1;
      }
    });

    try {
      if (initialLoad) {
        _totalPages = await _calculateTotalPages();
        _games.clear();
      }

      final games = await _gameService.getGamesPaginated(
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _currentSortBy,
        descending: _isDescending,
      );

      setState(() {
        _games.addAll(games);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败：${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreGames() async {
    if (_isLoading || _currentPage >= _totalPages) return;

    _currentPage++;
    await _loadGames(initialLoad: false);
  }

  Future<int> _calculateTotalPages() async {
    final totalCount = await _gameService.getTotalGamesCount();
    return (totalCount / _pageSize).ceil();
  }

  Future<void> _refreshData() async {
    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      await _loadGames();
    } finally {
      loadingObserver.hideLoading();
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('筛选与排序'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('最新发布'),
                onTap: () {
                  Navigator.pop(context);
                  _updateSorting('createTime', true);
                },
              ),
              ListTile(
                title: Text('最多浏览'),
                onTap: () {
                  Navigator.pop(context);
                  _updateSorting('viewCount', true);
                },
              ),
              ListTile(
                title: Text('最高评分'),
                onTap: () {
                  Navigator.pop(context);
                  _updateSorting('rating', true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateSorting(String sortBy, bool descending) {
    setState(() {
      _currentSortBy = sortBy;
      _isDescending = descending;
    });
    _loadGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('游戏列表'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildContent(),
      ),
      floatingActionButton: AdminCheck(
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/game/add');
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildError(_errorMessage!);
    }

    if (_games.isEmpty && _isLoading) {
      return _buildLoading();
    }

    if (_games.isEmpty) {
      return _buildEmptyState(context, '暂无游戏数据');
    }

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _games.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _games.length) {
          return GameCard(game: _games[index]);
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.games_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 24),
          AdminCheck(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/game/add');
              },
              child: Text('添加游戏'),
            ),
          ),
        ],
      ),
    );
  }
}
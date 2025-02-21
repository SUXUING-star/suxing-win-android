import 'package:flutter/material.dart';
import '../../models/game/game.dart';
import '../../services/main/game/game_service.dart';
import '../../utils/check/admin_check.dart';
import '../../utils/device/device_utils.dart';
import '../../widgets/components/screen/game/card/game_card.dart';
import '../../utils/load/loading_route_observer.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../utils/device/device_utils.dart';

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
  bool _isDisposed = false; // 添加标志位追踪组件状态

  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 使用 mounted 检查确保组件仍在树中
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;  // 再次检查，因为回调可能在组件销毁后执行

      final loadingObserver = Navigator.of(context)
          .widget.observers
          .whereType<LoadingRouteObserver>()
          .first;

      loadingObserver.showLoading();

      _loadGames().then((_) {
        if (!mounted) return;  // 确保组件仍然存在
        loadingObserver.hideLoading();
      });
    });

    _scrollController.addListener(_onScroll);
  }


  @override
  void dispose() {
    _isDisposed = true; // 标记组件已销毁
    _scrollController.removeListener(_onScroll);
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
    if (!mounted) return;  // 提前检查组件状态

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
        if (!mounted) return;  // 检查异步操作后的组件状态
        _games.clear();
      }

      final games = await _gameService.getGamesPaginated(
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _currentSortBy,
        descending: _isDescending,
      );

      if (!mounted) return;  // 再次检查组件状态

      setState(() {
        _games.addAll(games);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;  // 错误处理前检查组件状态

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
    if (!mounted) return;

    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      await _loadGames();
    } finally {
      if (mounted) {  // 确保在显示/隐藏加载指示器时组件仍然存在
        loadingObserver.hideLoading();
      }
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
      appBar: CustomAppBar(
        title: '游戏列表',
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
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
      controller: _scrollController, // Only needed in GamesListScreen
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        childAspectRatio: DeviceUtils.calculateCardRatio(context),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _games.length + (_isLoading ? 1 : 0), // The +1 part only for GamesListScreen
      itemBuilder: (context, index) {
        if (index < _games.length) {
          return GameCard(game: _games[index]);
        } else {
          return Center(child: CircularProgressIndicator()); // Only for GamesListScreen
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
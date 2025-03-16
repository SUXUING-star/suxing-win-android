// lib/screens/profile/history_screen.dart
import 'package:flutter/material.dart';
import '../../../services/main/history/game_history_service.dart';
import '../../../services/main/history/post_history_service.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/load/loading_route_observer.dart';
import '../../../utils/datetime/date_time_formatter.dart';
import '../../../widgets/common/appbar/custom_app_bar.dart';
import '../../../widgets/common/image/safe_cached_image.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final GameHistoryService _gameHistoryService = GameHistoryService();
  final PostHistoryService _postHistoryService = PostHistoryService();

  TabController? _tabController;
  String? _error;

  // 标记是否已经加载过数据
  bool _gameHistoryLoaded = false;
  bool _postHistoryLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 监听标签页变化，实现懒加载
    _tabController!.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 应用启动时只预加载当前选中的标签页数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialTab();
    });
  }

  // 加载初始标签页数据
  void _loadInitialTab() {
    if (_tabController!.index == 0) {
      _loadGameHistory();
    } else {
      _loadPostHistory();
    }
  }

  // 处理标签页变化事件，实现懒加载
  void _handleTabChange() {
    if (_tabController!.indexIsChanging) {
      return;
    }

    if (_tabController!.index == 0 && !_gameHistoryLoaded) {
      _loadGameHistory();
    } else if (_tabController!.index == 1 && !_postHistoryLoaded) {
      _loadPostHistory();
    }
  }

  // 只加载游戏历史
  Future<void> _loadGameHistory() async {
    if (_gameHistoryLoaded) return;

    final loadingObserver = Navigator.of(context)
        .widget
        .observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();

    try {
      // 只获取游戏历史数据
      await _gameHistoryService.getGameHistoryWithDetails(1, 10);
      setState(() {
        _gameHistoryLoaded = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = '加载游戏历史失败: $e';
      });
    } finally {
      loadingObserver.hideLoading();
    }
  }

  // 只加载帖子历史
  Future<void> _loadPostHistory() async {
    if (_postHistoryLoaded) return;

    final loadingObserver = Navigator.of(context)
        .widget
        .observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();

    try {
      // 只获取帖子历史数据
      await _postHistoryService.getPostHistoryWithDetails(1, 10);
      setState(() {
        _postHistoryLoaded = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = '加载帖子历史失败: $e';
      });
    } finally {
      loadingObserver.hideLoading();
    }
  }

  // 刷新当前选中的历史
  Future<void> _refreshCurrentHistory() async {
    int currentTab = _tabController!.index;

    if (currentTab == 0) {
      // 刷新游戏历史
      setState(() {
        _gameHistoryLoaded = false;
      });
      await _loadGameHistory();
    } else {
      // 刷新帖子历史
      setState(() {
        _postHistoryLoaded = false;
      });
      await _loadPostHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '浏览历史'),
      body: RefreshIndicator(
        onRefresh: _refreshCurrentHistory,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialTab,
              child: Text('重新加载'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '游戏浏览历史'),
            Tab(text: '帖子浏览历史'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 游戏历史标签页 - 使用组件拆分提高性能
              GameHistoryTab(
                isLoaded: _gameHistoryLoaded,
                onLoad: _loadGameHistory,
                gameHistoryService: _gameHistoryService,
              ),
              // 帖子历史标签页 - 使用组件拆分提高性能
              PostHistoryTab(
                isLoaded: _postHistoryLoaded,
                onLoad: _loadPostHistory,
                postHistoryService: _postHistoryService,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 游戏历史标签页 - 独立组件更易于维护
class GameHistoryTab extends StatefulWidget {
  final bool isLoaded;
  final VoidCallback onLoad;
  final GameHistoryService gameHistoryService;

  const GameHistoryTab({
    Key? key,
    required this.isLoaded,
    required this.onLoad,
    required this.gameHistoryService,
  }) : super(key: key);

  @override
  _GameHistoryTabState createState() => _GameHistoryTabState();
}

class _GameHistoryTabState extends State<GameHistoryTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _gameHistoryWithDetails;
  Map<String, dynamic>? _gameHistoryPagination;
  bool _isLoading = false;
  int _page = 1;
  final int _pageSize = 10;

  @override
  bool get wantKeepAlive => true; // 保持状态，避免切换标签页时重建

  @override
  void initState() {
    super.initState();
    // 使用addPostFrameCallback确保不在build过程中调用setState
    if (widget.isLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadHistory();
      });
    }
  }

  @override
  void didUpdateWidget(GameHistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoaded && !oldWidget.isLoaded) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await widget.gameHistoryService.getGameHistoryWithDetails(_page, _pageSize);

      setState(() {
        // 安全地处理游戏历史数据
        if (results.containsKey('history') && results['history'] is List) {
          final historyData = results['history'] as List;
          _gameHistoryWithDetails = historyData
              .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
              .toList();
        } else {
          _gameHistoryWithDetails = [];
        }

        // 安全地处理游戏分页数据
        if (results.containsKey('pagination') && results['pagination'] is Map) {
          _gameHistoryPagination = Map<String, dynamic>.from(results['pagination'] as Map);
        } else {
          _gameHistoryPagination = {'page': _page, 'limit': _pageSize, 'total': 0, 'totalPages': 0};
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoading) return;
    if (_gameHistoryPagination == null) return;

    // 检查是否已到最后一页
    final int totalPages = _gameHistoryPagination!['totalPages'] as int? ?? 1;
    if (_page >= totalPages) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 加载下一页
      _page++;
      final results = await widget.gameHistoryService.getGameHistoryWithDetails(_page, _pageSize);

      // 安全地处理新的游戏历史数据
      List<Map<String, dynamic>> newItems = [];
      if (results.containsKey('history') && results['history'] is List) {
        final historyData = results['history'] as List;
        newItems = historyData
            .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
            .toList();
      }

      setState(() {
        if (newItems.isNotEmpty) {
          _gameHistoryWithDetails = [...?_gameHistoryWithDetails, ...newItems];
        }

        // 安全地处理分页数据
        if (results.containsKey('pagination') && results['pagination'] is Map) {
          _gameHistoryPagination = Map<String, dynamic>.from(results['pagination'] as Map);
        } else {
          _gameHistoryPagination = {'page': _page, 'limit': _pageSize, 'total': 0, 'totalPages': 0};
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _page--; // 失败时回滚页码
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.isLoaded) {
      return Center(
        child: ElevatedButton(
          onPressed: widget.onLoad,
          child: Text('加载游戏历史'),
        ),
      );
    }

    if (_isLoading && (_gameHistoryWithDetails == null || _gameHistoryWithDetails!.isEmpty)) {
      return Center(child: CircularProgressIndicator());
    }

    if (_gameHistoryWithDetails == null || _gameHistoryWithDetails!.isEmpty) {
      return Center(
        child: Text('暂无游戏浏览记录'),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && !_isLoading) {
          _loadMoreHistory();
        }
        return true;
      },
      child: ListView.builder(
        itemCount: _gameHistoryWithDetails!.length + 1, // +1 for the loading indicator
        itemBuilder: (context, index) {
          if (index == _gameHistoryWithDetails!.length) {
            // 显示加载指示器或"没有更多"信息
            if (_isLoading) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ));
            } else if (_gameHistoryPagination != null &&
                _page < (_gameHistoryPagination!['totalPages'] as int? ?? 1)) {
              return Center(
                child: TextButton(
                  onPressed: _loadMoreHistory,
                  child: Text('加载更多'),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }

          final historyItem = _gameHistoryWithDetails![index];

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: SizedBox(
                width: 40,
                height: 40,
                child: ClipOval(
                  child: SafeCachedImage(
                    imageUrl: historyItem['coverImage']?.toString() ?? '',
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    onError: (url, error) {
                      print('历史记录游戏封面加载失败: $url, 错误: $error');
                    },
                  ),
                ),
              ),
              title: Text(historyItem['title']?.toString() ?? '未知游戏'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('上次浏览: ${DateTimeFormatter.formatStandard(
                      DateTime.parse(historyItem['lastViewTime']?.toString() ?? DateTime.now().toIso8601String())
                  )}'),
                  if (historyItem['category'] != null)
                    Text('分类: ${historyItem['category']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
              onTap: () {
                // 创建一个game对象或直接使用ID
                final gameId = historyItem['gameId']?.toString() ?? '';
                if (gameId.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.gameDetail,
                    arguments: gameId,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// 帖子历史标签页 - 独立组件更易于维护
class PostHistoryTab extends StatefulWidget {
  final bool isLoaded;
  final VoidCallback onLoad;
  final PostHistoryService postHistoryService;

  const PostHistoryTab({
    Key? key,
    required this.isLoaded,
    required this.onLoad,
    required this.postHistoryService,
  }) : super(key: key);

  @override
  _PostHistoryTabState createState() => _PostHistoryTabState();
}

class _PostHistoryTabState extends State<PostHistoryTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _postHistoryWithDetails;
  Map<String, dynamic>? _postHistoryPagination;
  bool _isLoading = false;
  int _page = 1;
  final int _pageSize = 10;

  @override
  bool get wantKeepAlive => true; // 保持状态，避免切换标签页时重建

  @override
  void initState() {
    super.initState();
    // 使用addPostFrameCallback确保不在build过程中调用setState
    if (widget.isLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadHistory();
      });
    }
  }

  @override
  void didUpdateWidget(PostHistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoaded && !oldWidget.isLoaded) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await widget.postHistoryService.getPostHistoryWithDetails(_page, _pageSize);

      setState(() {
        // 安全地处理帖子历史数据
        if (results.containsKey('history') && results['history'] is List) {
          final historyData = results['history'] as List;
          _postHistoryWithDetails = historyData
              .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
              .toList();
        } else {
          _postHistoryWithDetails = [];
        }

        // 安全地处理帖子分页数据
        if (results.containsKey('pagination') && results['pagination'] is Map) {
          _postHistoryPagination = Map<String, dynamic>.from(results['pagination'] as Map);
        } else {
          _postHistoryPagination = {'page': _page, 'limit': _pageSize, 'total': 0, 'totalPages': 0};
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoading) return;
    if (_postHistoryPagination == null) return;

    // 检查是否已到最后一页
    final int totalPages = _postHistoryPagination!['totalPages'] as int? ?? 1;
    if (_page >= totalPages) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 加载下一页
      _page++;
      final results = await widget.postHistoryService.getPostHistoryWithDetails(_page, _pageSize);

      // 安全地处理新的帖子历史数据
      List<Map<String, dynamic>> newItems = [];
      if (results.containsKey('history') && results['history'] is List) {
        final historyData = results['history'] as List;
        newItems = historyData
            .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
            .toList();
      }

      setState(() {
        if (newItems.isNotEmpty) {
          _postHistoryWithDetails = [...?_postHistoryWithDetails, ...newItems];
        }

        // 安全地处理分页数据
        if (results.containsKey('pagination') && results['pagination'] is Map) {
          _postHistoryPagination = Map<String, dynamic>.from(results['pagination'] as Map);
        } else {
          _postHistoryPagination = {'page': _page, 'limit': _pageSize, 'total': 0, 'totalPages': 0};
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _page--; // 失败时回滚页码
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.isLoaded) {
      return Center(
        child: ElevatedButton(
          onPressed: widget.onLoad,
          child: Text('加载帖子历史'),
        ),
      );
    }

    if (_isLoading && (_postHistoryWithDetails == null || _postHistoryWithDetails!.isEmpty)) {
      return Center(child: CircularProgressIndicator());
    }

    if (_postHistoryWithDetails == null || _postHistoryWithDetails!.isEmpty) {
      return Center(
        child: Text('暂无帖子浏览记录'),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && !_isLoading) {
          _loadMoreHistory();
        }
        return true;
      },
      child: ListView.builder(
        itemCount: _postHistoryWithDetails!.length + 1, // +1 for the loading indicator
        itemBuilder: (context, index) {
          if (index == _postHistoryWithDetails!.length) {
            // 显示加载指示器或"没有更多"信息
            if (_isLoading) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ));
            } else if (_postHistoryPagination != null &&
                _page < (_postHistoryPagination!['totalPages'] as int? ?? 1)) {
              return Center(
                child: TextButton(
                  onPressed: _loadMoreHistory,
                  child: Text('加载更多'),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }

          final historyItem = _postHistoryWithDetails![index];

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(historyItem['title']?.toString() ?? '未知帖子'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('上次浏览: ${DateTimeFormatter.formatStandard(
                      DateTime.parse(historyItem['lastViewTime']?.toString() ?? DateTime.now().toIso8601String())
                  )}'),
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye, size: 12, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text('${historyItem['viewCount'] ?? 0}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.comment, size: 12, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text('${historyItem['replyCount'] ?? 0}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                final postId = historyItem['postId']?.toString() ?? '';
                if (postId.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.postDetail,
                    arguments: postId,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
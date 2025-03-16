// lib/screens/profile/tab/game_history_tab.dart
import 'package:flutter/material.dart';
import '../../../../../services/main/history/game_history_service.dart';
import '../../../../../utils/device/device_utils.dart';
import './layout/game_history_grid_card.dart';  // 导入网格布局卡片
import './card/game_history_list_card.dart';  // 导入列表布局卡片


// 游戏历史标签页 - 优化UI显示
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

  Widget _buildInitialLoadButton() {
    return Center(
      child: ElevatedButton(
        onPressed: widget.onLoad,
        child: Text('加载游戏历史'),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            '暂无游戏浏览记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '浏览游戏后，您的历史记录将显示在这里',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircularProgressIndicator(),
    ));
  }

  Widget _buildLoadMoreButton() {
    return Center(
      child: TextButton(
        onPressed: _loadMoreHistory,
        child: Text('加载更多'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.isLoaded) {
      return _buildInitialLoadButton();
    }

    if (_isLoading && (_gameHistoryWithDetails == null || _gameHistoryWithDetails!.isEmpty)) {
      return _buildLoadingIndicator();
    }

    if (_gameHistoryWithDetails == null || _gameHistoryWithDetails!.isEmpty) {
      return _buildEmptyState();
    }

    // 根据设备类型选择不同的布局
    final isDesktop = DeviceUtils.isDesktop;
    final isTablet = DeviceUtils.isTablet(context);
    final isLandscape = DeviceUtils.isLandscape(context);

    if (isDesktop || (isTablet && isLandscape)) {
      return _buildGridLayout(context);
    } else {
      return _buildListLayout(context);
    }
  }

  // 列表布局 - 适用于移动设备
  Widget _buildListLayout(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && !_isLoading) {
          _loadMoreHistory();
        }
        return true;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          _page = 1;
          await _loadHistory();
        },
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _gameHistoryWithDetails!.length + 1, // +1 for the loading indicator
          itemBuilder: (context, index) {
            if (index == _gameHistoryWithDetails!.length) {
              // 显示加载指示器或"没有更多"信息
              if (_isLoading) {
                return _buildLoadMoreIndicator();
              } else if (_gameHistoryPagination != null &&
                  _page < (_gameHistoryPagination!['totalPages'] as int? ?? 1)) {
                return _buildLoadMoreButton();
              } else {
                return const SizedBox.shrink(); // No more items, return an empty SizedBox.
              }
            }

            final historyItem = _gameHistoryWithDetails![index];
            return GameHistoryListCard(historyItem: historyItem); // 使用分离的列表卡片组件
          },
        ),
      ),
    );
  }

  // 网格布局 - 适用于桌面和平板
  Widget _buildGridLayout(BuildContext context) {
    // 计算一行显示的卡片数量
    final crossAxisCount = DeviceUtils.calculateCardsPerRow(context);
    // 计算卡片比例
    final cardRatio = DeviceUtils.calculateSimpleCardRatio(context);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && !_isLoading) {
          _loadMoreHistory();
        }
        return true;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          _page = 1;
          await _loadHistory();
        },
        child: GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: cardRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _gameHistoryWithDetails!.length + 1, // +1 for the loading indicator
          itemBuilder: (context, index) {
            if (index == _gameHistoryWithDetails!.length) {
              // 显示加载指示器或"没有更多"信息
              if (_isLoading) {
                return _buildLoadMoreIndicator();
              } else if (_gameHistoryPagination != null &&
                  _page < (_gameHistoryPagination!['totalPages'] as int? ?? 1)) {
                return _buildLoadMoreButton();
              } else {
                return const SizedBox.shrink(); // No more items, return an empty SizedBox.
              }
            }

            final historyItem = _gameHistoryWithDetails![index];
            return GameHistoryGridCard(historyItem: historyItem); // 使用分离的网格卡片组件
          },
        ),
      ),
    );
  }
}
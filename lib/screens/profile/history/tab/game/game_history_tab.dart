// lib/screens/profile/tab/game_history_tab.dart
import 'package:flutter/material.dart';
import '../../../../services/main/history/game_history_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/datetime/date_time_formatter.dart';
import '../../../../utils/device/device_utils.dart';
import '../../../../widgets/common/image/safe_cached_image.dart';

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
            return _buildHistoryCard(historyItem);
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
            return _buildHistoryGridCard(historyItem);
          },
        ),
      ),
    );
  }

  // 历史记录卡片 - 列表样式
  Widget _buildHistoryCard(Map<String, dynamic> historyItem) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          final gameId = historyItem['gameId']?.toString() ?? '';
          if (gameId.isNotEmpty) {
            Navigator.pushNamed(
              context,
              AppRoutes.gameDetail,
              arguments: gameId,
            );
          }
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 游戏封面
              SizedBox(
                width: 100,
                height: 75,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeCachedImage(
                      imageUrl: historyItem['coverImage']?.toString() ?? '',
                      fit: BoxFit.cover,
                      onError: (url, error) {
                        print('历史记录游戏封面加载失败: $url, 错误: $error');
                      },
                    ),
                    if (historyItem['category'] != null)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            historyItem['category']?.toString() ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 游戏信息
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        historyItem['title']?.toString() ?? '未知游戏',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '上次浏览: ${DateTimeFormatter.formatStandard(
                            DateTime.parse(historyItem['lastViewTime']?.toString() ?? DateTime.now().toIso8601String())
                        )}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      Spacer(),
                      Row(
                        children: [
                          Icon(Icons.remove_red_eye, size: 14, color: Colors.blueAccent),
                          SizedBox(width: 4),
                          Text(
                            '${historyItem['viewCount'] ?? 0}',
                            style: TextStyle(fontSize: 12),
                          ),
                          if (historyItem['rating'] != null) ...[
                            SizedBox(width: 12),
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              '${historyItem['rating']}',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 历史记录卡片 - 网格样式
  Widget _buildHistoryGridCard(Map<String, dynamic> historyItem) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          final gameId = historyItem['gameId']?.toString() ?? '';
          if (gameId.isNotEmpty) {
            Navigator.pushNamed(
              context,
              AppRoutes.gameDetail,
              arguments: gameId,
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 游戏封面
                  SafeCachedImage(
                    imageUrl: historyItem['coverImage']?.toString() ?? '',
                    fit: BoxFit.cover,
                    onError: (url, error) {
                      print('历史游戏封面加载失败: $url, 错误: $error');
                    },
                  ),

                  // 类别标签
                  if (historyItem['category'] != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          historyItem['category']?.toString() ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // 上次浏览时间
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            DateTimeFormatter.formatRelative(
                              DateTime.parse(historyItem['lastViewTime']?.toString() ?? DateTime.now().toIso8601String()),
                            ),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 游戏信息
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      historyItem['title']?.toString() ?? '未知游戏',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    if (historyItem['summary'] != null)
                      Text(
                        historyItem['summary']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    Spacer(),

                    // 浏览次数和上次浏览时间
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.visibility, size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              '${historyItem['viewCount'] ?? 0}次',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateTimeFormatter.formatShort(
                            DateTime.parse(historyItem['lastViewTime']?.toString() ?? DateTime.now().toIso8601String()),
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
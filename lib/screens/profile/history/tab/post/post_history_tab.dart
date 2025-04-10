// lib/screens/profile/tab/post_history_tab.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import './card/post_history_card.dart'; // Import the new widget

// 帖子历史标签页 - 优化UI显示
class PostHistoryTab extends StatefulWidget {
  final bool isLoaded;
  final VoidCallback onLoad;
  final ForumService forumService;

  const PostHistoryTab({
    Key? key,
    required this.isLoaded,
    required this.onLoad,
    required this.forumService,
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
      final results = await widget.forumService.getPostHistoryWithDetails(_page, _pageSize);

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
      final results = await widget.forumService.getPostHistoryWithDetails(_page, _pageSize);

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

  Widget _buildInitialLoadButton() {
    return Center(
      child: ElevatedButton(
        onPressed: widget.onLoad,
        child: Text('加载帖子历史'),
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
          Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            '暂无帖子浏览记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '浏览社区帖子后，您的历史记录将显示在这里',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircularProgressIndicator(),
      ),
    );
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

    if (_isLoading && (_postHistoryWithDetails == null || _postHistoryWithDetails!.isEmpty)) {
      return _buildLoadingIndicator();
    }

    if (_postHistoryWithDetails == null || _postHistoryWithDetails!.isEmpty) {
      return _buildEmptyState();
    }

    return _buildListLayout(context);
  }

  // 列表布局 - 帖子历史使用列表布局
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
          itemCount: _postHistoryWithDetails!.length + 1, // +1 for the loading indicator
          itemBuilder: (context, index) {
            if (index == _postHistoryWithDetails!.length) {
              // 显示加载指示器或"没有更多"信息
              if (_isLoading) {
                return _buildLoadMoreIndicator();
              } else if (_postHistoryPagination != null &&
                  _page < (_postHistoryPagination!['totalPages'] as int? ?? 1)) {
                return _buildLoadMoreButton();
              } else {
                return const SizedBox.shrink(); // No more items, return an empty SizedBox.
              }
            }

            final historyItem = _postHistoryWithDetails![index];
            return PostHistoryCard(historyItem: historyItem); // Use the new widget
          },
        ),
      ),
    );
  }
}
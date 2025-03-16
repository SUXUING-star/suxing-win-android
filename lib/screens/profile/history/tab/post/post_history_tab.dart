// lib/screens/profile/tab/post_history_tab.dart
import 'package:flutter/material.dart';
import '../../../../services/main/history/post_history_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/datetime/date_time_formatter.dart';

// 帖子历史标签页 - 优化UI显示
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
            return _buildPostHistoryCard(historyItem);
          },
        ),
      ),
    );
  }

  // 改进的帖子历史卡片
  Widget _buildPostHistoryCard(Map<String, dynamic> historyItem) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
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
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                historyItem['title']?.toString() ?? '未知帖子',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 8),

              // 帖子内容预览
              if (historyItem['content'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    historyItem['content']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // 帖子作者信息
              if (historyItem['authorName'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        historyItem['authorName']?.toString() ?? '匿名用户',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

              // 底部统计信息和浏览时间
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧统计信息
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye, size: 14, color: Colors.blueAccent),
                      SizedBox(width: 4),
                      Text(
                        '${historyItem['viewCount'] ?? 0}',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.comment, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        '${historyItem['replyCount'] ?? 0}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),

                  // 右侧浏览时间
                  Row(
                    children: [
                      Icon(Icons.history, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        DateTimeFormatter.formatRelative(
                          DateTime.parse(historyItem['lastViewTime']?.toString() ?? DateTime.now().toIso8601String()),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
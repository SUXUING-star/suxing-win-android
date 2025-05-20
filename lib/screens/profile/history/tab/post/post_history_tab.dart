// lib/screens/profile/tab/post_history_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import './card/post_history_card.dart'; // Import the new widget

// 帖子历史标签页 - 优化UI显示
class PostHistoryTab extends StatefulWidget {
  final bool isLoaded;
  final VoidCallback onLoad;

  const PostHistoryTab({
    super.key,
    required this.isLoaded,
    required this.onLoad,
  });

  @override
  _PostHistoryTabState createState() => _PostHistoryTabState();
}

class _PostHistoryTabState extends State<PostHistoryTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _postHistoryWithDetails;
  Map<String, dynamic>? _postHistoryPagination;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _hasInitializedDependencies = false;
  late int _page;
  final int _pageSize = 10;
  late final ForumService _forumService;

  @override
  bool get wantKeepAlive => true; // 保持状态，避免切换标签页时重建

  @override
  void initState() {
    super.initState();
    _page = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _forumService = context.read<ForumService>();
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      if (widget.isLoaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadHistory(); // 增加 mounted 检查
        });
      } else {
        _isInitialLoading = false; // 如果初始未加载，则不需要播放首次加载动画
      }
    }
  }

  @override
  void didUpdateWidget(PostHistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 isLoaded 从 false 变为 true 时，触发加载
    if (widget.isLoaded && !oldWidget.isLoaded) {
      _page = 1; // 重置页码
      _postHistoryWithDetails = null; // 清空旧数据
      _isInitialLoading = true; // 标记为首次加载（对于这个 Tab 来说）
      _loadHistory();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (_isLoading || !mounted) return; // 增加 mounted 检查

    setState(() {
      _isLoading = true;
      // 首次加载不清空数据，让 loading 覆盖初始按钮
      if (_page > 1) {
        // 加载更多时不清空
      } else if (!_isInitialLoading && _postHistoryWithDetails != null) {
        // 非首次加载（如下拉刷新）时清空
        _postHistoryWithDetails = null;
      }
    });

    try {
      final results =
          await _forumService.getPostHistoryWithDetails(_page, _pageSize);

      if (!mounted) return; // 异步操作后再次检查

      List<Map<String, dynamic>> currentItems = _postHistoryWithDetails ?? [];
      List<Map<String, dynamic>> newItems = [];
      Map<String, dynamic>? paginationData;

      // 安全处理... (保持不变)
      if (results.containsKey('history') && results['history'] is List) {
        final historyData = results['history'] as List;
        newItems = historyData
            .map((item) => item is Map
                ? Map<String, dynamic>.from(item)
                : <String, dynamic>{})
            .toList();
      }
      if (results.containsKey('pagination') && results['pagination'] is Map) {
        paginationData =
            Map<String, dynamic>.from(results['pagination'] as Map);
      } else {
        paginationData = {
          'page': _page,
          'limit': _pageSize,
          'total': 0,
          'totalPages': 0
        };
      }

      setState(() {
        if (_page == 1) {
          _postHistoryWithDetails = newItems; // 覆盖
        } else {
          _postHistoryWithDetails = [...currentItems, ...newItems]; // 追加
        }
        _postHistoryPagination = paginationData;
        _isLoading = false;
        if (_isInitialLoading) _isInitialLoading = false; // 首次加载动画条件满足后重置标记
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isInitialLoading = false; // 加载失败也算完成了首次尝试
        // 可以考虑显示错误信息
      });
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoading || !mounted) return;
    if (_postHistoryPagination == null) return;

    final int totalPages = _postHistoryPagination!['totalPages'] as int? ?? 1;
    if (_page >= totalPages) return;

    // 不需要再次设置 _isLoading = true，因为 _buildListLayout 中的 itemBuilder 会显示加载指示器
    _page++; // 移到 try 之前，避免 catch 中重复 --
    // setState(() { _isLoading = true; }); // 不需要，让UI驱动

    try {
      final results =
          await _forumService.getPostHistoryWithDetails(_page, _pageSize);
      if (!mounted) return;

      List<Map<String, dynamic>> currentItems = _postHistoryWithDetails ?? [];
      List<Map<String, dynamic>> newItems = [];
      Map<String, dynamic>? paginationData;

      // 安全处理
      if (results.containsKey('history') && results['history'] is List) {
        final historyData = results['history'] as List;
        newItems = historyData
            .map((item) => item is Map
                ? Map<String, dynamic>.from(item)
                : <String, dynamic>{})
            .toList();
      }
      if (results.containsKey('pagination') && results['pagination'] is Map) {
        paginationData =
            Map<String, dynamic>.from(results['pagination'] as Map);
      } else {
        paginationData = {
          'page': _page,
          'limit': _pageSize,
          'total': 0,
          'totalPages': 0
        };
      }

      setState(() {
        if (newItems.isNotEmpty) {
          _postHistoryWithDetails = [...currentItems, ...newItems]; // 追加
        }
        _postHistoryPagination = paginationData;
        // _isLoading = false; // 由 ListView 的 itemCount 控制加载状态显示
      });
    } catch (e) {
      if (!mounted) return;
      _page--; // 失败时回滚页码
      // setState(() { _isLoading = false; }); // 同上
      // 显示错误提示...
    }
  }

  Widget _buildInitialLoadButton() {
    return Center(
      child: FadeInSlideUpItem(
        // 添加动画
        child: FunctionalTextButton(
          onPressed: widget.onLoad,
          label: '加载浏览记录',
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return LoadingWidget.inline(message: "正在加载数据...");
  }

  Widget _buildEmptyState() {
    return FadeInSlideUpItem(
      // 添加动画
      child: EmptyStateWidget(
        message: '暂无帖子浏览记录',
        iconColor: Colors.grey[400],
        iconData: Icons.forum_outlined,
        iconSize: 64,
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return LoadingWidget.inline(message: "加载更多...");
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      // 给加载更多加点边距
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: FadeInItem(
          // 添加动画
          child: FunctionalTextButton(
            onPressed: _loadMoreHistory,
            label: '加载更多',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.isLoaded) {
      return _buildInitialLoadButton();
    }

    if (_isLoading &&
        (_postHistoryWithDetails == null || _postHistoryWithDetails!.isEmpty)) {
      return _buildLoadingIndicator();
    }

    if (_postHistoryWithDetails == null || _postHistoryWithDetails!.isEmpty) {
      return _buildEmptyState();
    }

    return _buildListLayout(context);
  }

  // 列表布局 - 帖子历史使用列表布局
  Widget _buildListLayout(BuildContext context) {
    // 添加 Key
    final listKey = ValueKey<int>(_postHistoryWithDetails?.length ?? 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // 滚动到底部加载更多逻辑保持不变
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent * 0.9 && // 阈值调整
            !_isLoading) {
          _loadMoreHistory();
        }
        return true;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          _page = 1;
          _isInitialLoading = true; // 刷新时也认为是“首次”加载动画
          await _loadHistory();
        },
        child: ListView.builder(
          key: listKey, // 应用 Key
          padding: EdgeInsets.all(16),
          // itemCount 计算保持不变
          itemCount: (_postHistoryWithDetails?.length ?? 0) +
              1, // +1 for loading/button/empty
          itemBuilder: (context, index) {
            // 列表末尾的加载指示器/按钮逻辑
            if (index == (_postHistoryWithDetails?.length ?? 0)) {
              if (_isLoading && _page > 1) {
                // 仅在加载更多时显示 Loading
                return _buildLoadMoreIndicator();
              } else if (!_isLoading && // 未在加载
                  _postHistoryPagination != null &&
                  _page <
                      (_postHistoryPagination!['totalPages'] as int? ?? 1)) {
                return _buildLoadMoreButton(); // 显示加载更多按钮
              } else {
                // 没有更多数据或初始加载中（不显示任何东西）
                return const SizedBox.shrink();
              }
            }

            // --- 修改这里：为列表项添加动画 ---
            final historyItem = _postHistoryWithDetails![index];
            return FadeInSlideUpItem(
              // 只有在首次加载或刷新后才应用交错延迟动画
              delay: _isInitialLoading
                  ? Duration(milliseconds: 50 * index)
                  : Duration.zero,
              duration: Duration(milliseconds: 350),
              child: Padding(
                // 可以加一点垂直间距
                padding: const EdgeInsets.only(bottom: 8.0),
                child: PostHistoryCard(historyItem: historyItem),
              ),
            );
            // --- 结束修改 ---
          },
        ),
      ),
    );
  }
}

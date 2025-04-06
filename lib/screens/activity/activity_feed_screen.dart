// lib/screens/activity/activity_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:visibility_detector/visibility_detector.dart'; // <--- 引入 VisibilityDetector
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_type_filter.dart';
import 'package:suxingchahui/widgets/components/screen/activity/panel/hot_activities_panel.dart';
import 'package:suxingchahui/widgets/components/screen/activity/feed/collapsible_activity_feed.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // <--- 引入 LoadingWidget
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // <--- 引入 ErrorWidget (假设存在)

class ActivityFeedScreen extends StatefulWidget {
  final String? userId;
  final String? type;
  final String title;
  final bool useAlternatingLayout;
  final bool showHotActivities;

  const ActivityFeedScreen({
    Key? key, // <--- 接收 Key
    this.userId,
    this.type,
    this.title = '动态流',
    this.useAlternatingLayout = true,
    this.showHotActivities = true,
  }) : super(key: key); // <--- 传递 Key

  @override
  _ActivityFeedScreenState createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen>
    with SingleTickerProviderStateMixin {
  final UserActivityService _activityService = UserActivityService();
  final ScrollController _scrollController = ScrollController();

  // --- 数据和分页状态 ---
  List<UserActivity> _activities = [];
  PaginationData? _pagination;
  String _error = ''; // 错误信息
  int _currentPage = 1; // 当前页码 (用于分页加载)
  String? _selectedType; // 当前选择的过滤类型

  // --- UI 控制状态 ---
  bool _useAlternatingLayout = true;
  bool _showHotActivities = true;
  FeedCollapseMode _collapseMode = FeedCollapseMode.none;
  late AnimationController _refreshAnimationController; // 刷新动画

  // --- 懒加载核心状态 ---
  bool _isInitialized = false; // 是否已完成首次加载
  bool _isVisible = false;     // 当前 Widget 是否可见
  bool _isLoadingData = false; // 是否正在进行加载操作 (首次或刷新)
  bool _isLoadingMore = false; // 是否正在加载更多 (分页)
  // --- 结束懒加载状态 ---

  @override
  void initState() {
    super.initState();
    _useAlternatingLayout = widget.useAlternatingLayout;
    _showHotActivities = widget.showHotActivities;
    _selectedType = widget.type; // 初始化过滤类型
    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // --- 不在 initState 中加载数据 ---
    // _loadActivities();

    // 添加滚动监听器用于分页加载 (但只在初始化后才真正工作)
    _scrollController.addListener(_scrollListener);

  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  // --- 核心：触发首次数据加载 ---
  void _triggerInitialLoad() {
    // 仅在 Widget 变得可见且尚未初始化时执行
    if (_isVisible && !_isInitialized) {
      // 标记为已初始化，防止重复触发
      _isInitialized = true;
      // 调用实际加载方法，标记为首次加载
      _loadActivities(isInitialLoad: true);
    }
  }

  // --- 加载活动数据（核心方法，带懒加载逻辑）---
  Future<void> _loadActivities({bool isInitialLoad = false, bool isRefresh = false}) async {
    // 防止重复加载（刷新操作除外）
    if (_isLoadingData && !isRefresh) {
      return;
    }
    // 必须是初始化过的（或者由首次加载/刷新触发）才能继续
    if (!_isInitialized && !isInitialLoad && !isRefresh) {
      return;
    }
    // 如果正在加载更多，不允许同时进行首次/刷新加载
    if (_isLoadingMore) {
      return;
    }

    if (!mounted) return; // 检查 Widget 是否还在树中


    // 设置加载状态
    setState(() {
      _isLoadingData = true; // 标记开始加载（首次或刷新）
      _error = ''; // 清除旧错误
      // 如果是刷新或首次加载，重置页码和列表
      if (isRefresh || isInitialLoad) {
        _currentPage = 1;
        _activities = [];
        _pagination = null; // 重置分页信息
      }
    });

    // 如果是刷新，启动动画
    if (isRefresh) {
      _refreshAnimationController.forward(from: 0.0);
    }

    try {
      Map<String, dynamic> result;
      // 确定请求类型和参数 (总是请求第一页)
      List<String>? types = _selectedType != null ? [_selectedType!] : null;
      const int limit = 20; // 每页数量

      if (widget.userId != null) {
        result = await _activityService.getUserActivities(widget.userId!, page: 1, limit: limit, types: types);
      } else {
        result = await _activityService.getPublicActivities(page: 1, limit: limit);
      }

      if (!mounted) return; // 异步操作后再次检查

      // 解析结果并更新状态
      final List<UserActivity> fetchedActivities = result['activities'] ?? [];
      final PaginationData? fetchedPagination = result['pagination'];

      setState(() {
        _activities = fetchedActivities; // 替换列表数据
        _pagination = fetchedPagination;
        _currentPage = 1; // 确认当前是第一页
        _isLoadingData = false; // 结束加载状态
        print("ActivityFeedScreen (${widget.title}): Load/Refresh successful. Received ${_activities.length} activities.");
      });

    } catch (e, s) { // 捕获错误和堆栈
      print('ActivityFeedScreen (${widget.title}): Load activities error: $e\nStackTrace: $s');
      if (!mounted) return;
      setState(() {
        _error = '加载动态失败: $e'; // 设置错误信息
        _isLoadingData = false; // 结束加载状态
        _activities = []; // 清空列表
        _pagination = null; // 清空分页
      });
    }
  }

  // --- 加载更多活动数据 ---
  Future<void> _loadMoreActivities() async {
    // 必须初始化后才能加载更多
    // 必须没有错误
    // 不能同时进行首次/刷新加载 或 另一次加载更多
    // 必须有分页信息，且当前页小于总页数
    if (!_isInitialized || _error.isNotEmpty || _isLoadingData || _isLoadingMore || _pagination == null || _currentPage >= _pagination!.pages) {
      // print("ActivityFeedScreen (${widget.title}): Load more skipped (conditions not met).");
      return;
    }

    if (!mounted) return;
    final nextPage = _currentPage + 1;
    print("ActivityFeedScreen (${widget.title}): Loading more activities (page: $nextPage)");

    setState(() {
      _isLoadingMore = true; // 开始加载更多状态
    });

    try {
      Map<String, dynamic> result;
      // 确定请求类型和参数
      List<String>? types = _selectedType != null ? [_selectedType!] : null;
      const int limit = 20;

      // 请求下一页数据
      if (widget.userId != null) {
        result = await _activityService.getUserActivities(widget.userId!, page: nextPage, limit: limit, types: types);
      } else {
        result = await _activityService.getPublicActivities(page: nextPage, limit: limit);
      }

      if (!mounted) return; // 异步后检查

      final List<UserActivity> newActivities = result['activities'] ?? [];
      final PaginationData? newPagination = result['pagination'];

      // 更新状态：追加数据，更新页码和分页信息
      setState(() {
        _activities.addAll(newActivities);
        _pagination = newPagination; // 更新分页信息
        _currentPage = nextPage; // 更新当前页码
        _isLoadingMore = false; // 结束加载更多状态
        print("ActivityFeedScreen (${widget.title}): Load more successful. Total activities: ${_activities.length}");
      });

    } catch (e, s) { // 捕获错误
      print('ActivityFeedScreen (${widget.title}): Load more activities error: $e\nStackTrace: $s');
      if (!mounted) return;
      // 加载更多失败通常只提示，不设置全局错误状态
     AppSnackBar.showError(context,'加载更多失败: $e');
      setState(() {
        _isLoadingMore = false; // 结束加载更多状态
      });
    }
  }


  // --- 滚动监听器 ---
  void _scrollListener() {
    // 只有在初始化完成后才监听滚动到底部
    if (_isInitialized) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) { // 接近底部时触发
        _loadMoreActivities(); // 尝试加载更多
      }
    }
  }

  // --- 处理类型过滤变化 ---
  void _onTypeFilterChanged(String? type) {
    if (_selectedType != type) {
      print("ActivityFeedScreen (${widget.title}): Type filter changed to: $type");
      // 重置状态以强制重新加载
      setState(() {
        _selectedType = type;
        _isInitialized = false; // 标记为未初始化，以便重新触发加载
        _isVisible = false;     // 重置可见性，确保 VisibilityDetector 感知变化
        _activities = [];     // 清空当前列表
        _error = '';          // 清除错误
        _isLoadingData = false; // 重置加载状态
        _isLoadingMore = false;
        _currentPage = 1;
        _pagination = null;   // 清除分页信息
        // 重置滚动条到顶部
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
      print("ActivityFeedScreen (${widget.title}): State reset for new type filter, waiting for visibility trigger.");
      // 使用 microtask 尝试立即触发加载（如果仍然可见），改善用户体验
      Future.microtask(() {
        if (mounted && _isVisible) {
          _triggerInitialLoad();
        }
      });
    }
  }

  // --- UI 切换方法 (逻辑不变) ---
  void _toggleLayoutMode() { setState(() => _useAlternatingLayout = !_useAlternatingLayout); }
  void _toggleHotActivitiesPanel() { setState(() => _showHotActivities = !_showHotActivities); }
  void _toggleCollapseMode() {
    setState(() {
      // Cycle through collapse modes
      _collapseMode = FeedCollapseMode.values[(_collapseMode.index + 1) % FeedCollapseMode.values.length];
    });
  }

  // --- 辅助方法：获取折叠模式文本和图标 (逻辑不变) ---
  String _getCollapseModeText() {
    switch (_collapseMode) {
      case FeedCollapseMode.none: return '标准视图';
      case FeedCollapseMode.byUser: return '按用户折叠';
      case FeedCollapseMode.byType: return '按类型折叠';
    }
  }
  IconData _getCollapseModeIcon() {
    switch (_collapseMode) {
      case FeedCollapseMode.none: return Icons.view_agenda;
      case FeedCollapseMode.byUser: return Icons.people_outline;
      case FeedCollapseMode.byType: return Icons.category_outlined;
    }
  }

  // --- 导航到详情页 (逻辑不变) ---
  void _navigateToActivityDetail(UserActivity activity) {
    NavigationUtils.pushNamed(
      context,
      '/activity/detail', // Adjust route name if necessary
      arguments: {'activityId': activity.id, 'activity': activity},
    );
  }

  // --- 主构建方法 ---
  @override
  Widget build(BuildContext context) {
    // 使用 VisibilityDetector 包裹整个页面内容
    return VisibilityDetector(
      // 使用唯一的 Key，结合 widget key 或 title
      key: Key('activity_feed_visibility_${widget.key?.toString() ?? widget.title}'),
      // 当可见性变化时调用
      onVisibilityChanged: (VisibilityInfo info) {
        final bool currentlyVisible = info.visibleFraction > 0;
        // 仅在可见性状态实际改变时更新
        if (currentlyVisible != _isVisible) {
          // 使用 microtask 确保 setState 在 build 之后执行
          Future.microtask(() {
            if (mounted) {
              setState(() { _isVisible = currentlyVisible; });
            } else {
              _isVisible = currentlyVisible; // 更新内部变量即使 unmounted
            }
            // 如果变为可见，尝试触发初始加载
            if (_isVisible) {
              _triggerInitialLoad();
            }
          });
        }
      },
      // 构建实际的 UI 内容
      child: Scaffold(
        // AppBar 通常由外部 MainLayout 提供，这里不需要
        body: SafeArea( // 保证内容在安全区域内
          child: _buildBodyContent(), // 调用 Body 构建逻辑
        ),
      ),
    );
  }

  // --- 构建 Body 内容的逻辑 ---
  Widget _buildBodyContent() {
    // State 1: Not initialized (Waiting for visibility or initial load failed silently)
    if (!_isInitialized && !_isLoadingData) {
      return LoadingWidget.inline(message: "等待加载动态...");
    }
    // State 2: Loading initial data or refreshing, and the list is currently empty
    else if (_isLoadingData && _activities.isEmpty) {
      return LoadingWidget.inline(message: "正在加载动态...");
    }
    // State 3: Error occurred, and the list is empty
    else if (_error.isNotEmpty && _activities.isEmpty) {
      // 使用你的 ErrorWidget，或者自定义一个
      return InlineErrorWidget( // Assuming CustomErrorWidget exists
          errorMessage: _error,
          onRetry: () => _loadActivities(isRefresh: true));
    }
    // State 4: Data is ready (list might be populated or empty), or loading more
    else {
      // Build the main UI structure with controls and the feed
      return Column(
        children: [
          // --- Top Action Bar ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                // Collapse Mode Button
                Expanded(
                  child: InkWell(
                    onTap: _toggleCollapseMode,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getCollapseModeIcon(), size: 16, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(_getCollapseModeText(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Refresh Button
                RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0).animate(_refreshAnimationController),
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    // Refresh button always triggers a refresh load
                    onPressed: () => _loadActivities(isRefresh: true),
                    tooltip: '刷新',
                  ),
                ),
                // Layout Toggle Button
                IconButton(
                  icon: Icon(_useAlternatingLayout ? Icons.view_stream_outlined : Icons.chat_bubble_outline), // Different icons
                  onPressed: _toggleLayoutMode,
                  tooltip: _useAlternatingLayout ? '切换到标准布局' : '切换到聊天气泡布局',
                ),
                // Hot Activities Panel Toggle Button
                IconButton(
                  icon: Icon(_showHotActivities ? Icons.visibility_off_outlined : Icons.local_fire_department_outlined), // Different icons
                  onPressed: _toggleHotActivitiesPanel,
                  tooltip: _showHotActivities ? '隐藏热门动态' : '显示热门动态',
                ),
              ],
            ),
          ),

          // --- Main Content Area (Feed + Optional Panel) ---
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Left Side: Filters + Feed ---
                Expanded(
                  child: Column(
                    children: [
                      // Type Filter (Only show if filtering by user ID makes sense)
                      if (widget.userId != null)
                        ActivityTypeFilter(
                          selectedType: _selectedType,
                          onTypeSelected: _onTypeFilterChanged,
                        ),

                      // --- Activity Feed ---
                      Expanded(
                        child: CollapsibleActivityFeed(
                          activities: _activities,
                          // Pass loading states accurately to the feed component
                          isLoading: _isLoadingData && _activities.isEmpty, // Show feed's loading only if list is empty during load
                          isLoadingMore: _isLoadingMore, // Pass load more state
                          // Pass error only if the list is empty, otherwise handled by Snackbar
                          error: _error.isNotEmpty && _activities.isEmpty ? _error : '',
                          collapseMode: _collapseMode,
                          useAlternatingLayout: _useAlternatingLayout,
                          onActivityTap: _navigateToActivityDetail,
                          // Feed's internal refresh triggers our refresh logic
                          onRefresh: () => _loadActivities(isRefresh: true),
                          // Feed's load more triggers our load more logic
                          onLoadMore: _loadMoreActivities,
                          scrollController: _scrollController, // Pass the controller
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Right Side: Hot Activities Panel (Conditional) ---
                // HotActivitiesPanel likely handles its own loading/state
                if (_showHotActivities) const HotActivitiesPanel(),
              ],
            ),
          ),
        ],
      );
    }
  }
}
import 'dart:async'; // Timer, StreamSubscription
import 'package:flutter/material.dart';
// HapticFeedback
import 'package:hive/hive.dart'; // BoxEvent
import 'package:provider/provider.dart';
// 需要 Provider 获取 AuthProvider (如果 Card 里需要)
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart'; // 只依赖 Service
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_type_filter.dart';
import 'package:suxingchahui/widgets/components/screen/activity/panel/hot_activities_panel.dart';
import 'package:suxingchahui/widgets/components/screen/activity/feed/collapsible_activity_feed.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
// 需要类型工具
// 需要时间格式化
import 'package:visibility_detector/visibility_detector.dart'; // 需要可见性检测

class ActivityFeedScreen extends StatefulWidget {
  final String? userId; // 目标用户 ID (null 表示公共或关注流)
  final String? type; // 初始活动类型过滤
  final String title;
  final bool useAlternatingLayout;
  final bool showHotActivities;

  const ActivityFeedScreen({
    super.key,
    this.userId,
    this.type,
    this.title = '动态流', // 默认标题
    this.useAlternatingLayout = true, // 默认交替布局
    this.showHotActivities = true, // 默认显示热门
  });

  @override
  _ActivityFeedScreenState createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // --- 依赖 ---

  // --- UI 控制状态 ---
  final ScrollController _scrollController = ScrollController();
  bool _useAlternatingLayout = true;
  bool _showHotActivities = true;
  FeedCollapseMode _collapseMode = FeedCollapseMode.none; // 默认不折叠
  late AnimationController _refreshAnimationController;

  // --- 数据和分页状态 ---
  List<UserActivity> _activities = [];
  PaginationData? _pagination;
  String _error = ''; // 错误信息
  int _currentPage = 1; // 当前页码
  String? _selectedType; // 当前选中的过滤类型

  // --- 加载和可见性状态 ---
  bool _isInitialized = false; // 是否已完成首次加载调用
  bool _isVisible = false; // 当前 Widget 是否可见
  bool _isLoadingData = false; // 标记正在进行首次/刷新加载
  bool _isLoadingMore = false; // 标记正在加载更多 (分页)
  bool _needsRefresh = false; // 应用从后台恢复时是否需要刷新

  // --- 缓存监听 ---
  StreamSubscription<BoxEvent>? _cacheSubscription;
  String _currentWatchIdentifier = ''; // 记录当前监听的参数组合
  Timer? _refreshDebounceTimer; // 刷新防抖计时器

  // --- UI 层刷新控制 ---
  DateTime? _lastRefreshTime; // 记录上次成功刷新的时间
  final Duration _minUiRefreshInterval =
      const Duration(seconds: 5); // UI 层允许的最小刷新间隔

  // === 生命周期 ===
  @override
  void initState() {
    super.initState();
    // 从 widget 初始化状态
    _useAlternatingLayout = widget.useAlternatingLayout;
    _showHotActivities = widget.showHotActivities;
    _selectedType = widget.type;
    // 初始化动画控制器
    _refreshAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    // 添加滚动监听
    _scrollController.addListener(_scrollListener);
    // 添加 App 生命周期监听
    WidgetsBinding.instance.addObserver(this);
    print(
        "ActivityFeedScreen (${widget.title}) initState. Type: $_selectedType");
    // 首次加载由 VisibilityDetector 触发
  }

  @override
  void dispose() {
    // 移除监听和控制器
    WidgetsBinding.instance.removeObserver(this);
    _stopWatchingCache(); // 确保取消缓存监听
    _refreshDebounceTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 处理 App 从后台恢复
    if (state == AppLifecycleState.resumed) {
      if (_isVisible && _needsRefresh) {
        _refreshCurrentPageData(reason: "App Resumed with NeedsRefresh");
        _needsRefresh = false; // 重置标记
      } else if (_isVisible) {
        // 即使没有标记，也检查一下（例如，超过一定时间）
        _refreshCurrentPageData(reason: "App Resumed and Visible Check");
      }
    } else if (state == AppLifecycleState.paused) {
      // 可以考虑在这里设置 _needsRefresh = true;
    }
  }

  // === 缓存监听核心逻辑 ===
  void _startOrUpdateWatchingCache() {
    final String feedType = _getFeedType();
    final List<String>? types = _selectedType != null ? [_selectedType!] : null;
    final String newWatchIdentifier =
        "${feedType}_${widget.userId ?? 'none'}_p${_currentPage}_l20_t${types?.join('_') ?? 'all'}"; // 假设 limit 是 20

    if (_cacheSubscription != null &&
        _currentWatchIdentifier == newWatchIdentifier) {
      return; // 监听目标未变
    }

    _stopWatchingCache(); // 停止旧监听
    _currentWatchIdentifier = newWatchIdentifier;

    try {
      final activityService = context.read<UserActivityService>();
      _cacheSubscription = activityService
          .watchActivityFeedChanges(
        feedType: feedType, page: _currentPage, limit: 20, // 使用固定 limit
        userId: widget.userId, types: types,
      )
          .listen(
        (BoxEvent event) {
          // --- 关键判断在这里！ ---
          // 只在数据被删除时才触发刷新逻辑
          if (event.deleted) {
            if (_isVisible) {
              _refreshCurrentPageData(reason: "Cache Deleted Event");
            } else {
              _needsRefresh = true; // 标记在下次可见时刷新
            }
          } else {
            // 对于写入/更新事件 (event.deleted == false)，直接忽略，啥也不干
          }
          // --- 判断结束 ---
        },
        onError: (error, stackTrace) {
          _stopWatchingCache(); // 出错时停止监听
          _currentWatchIdentifier = ''; // 重置标识符，以便下次可以重新监听
        },
        onDone: () {
          // 可选：监听流关闭时的处理
          // 只有当监听目标仍然是当前目标时才清除标识符
          if (_currentWatchIdentifier == newWatchIdentifier) {
            _currentWatchIdentifier = '';
          }
        },
        cancelOnError: true, // 出错时自动取消订阅
      );
    } catch (e) {
      _currentWatchIdentifier = ''; // 启动失败，重置标识符
    }
  }

  void _stopWatchingCache() {
    if (_cacheSubscription != null) {
      _cacheSubscription!.cancel();
      _cacheSubscription = null;
      // 不清除 _currentWatchIdentifier，用于下次比较
    }
  }

  // 刷新当前页数据（带 UI 层防抖和节流）
  void _refreshCurrentPageData({required String reason}) {
    if (_isLoadingData || _isLoadingMore || !mounted) return;

    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minUiRefreshInterval) {
      return;
    }

    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && !_isLoadingData && !_isLoadingMore) {
        _loadActivities(
            isRefresh: true, pageToLoad: _currentPage); // 标记为刷新，加载当前页
      } else {
        if (mounted) _needsRefresh = true; // 标记稍后刷新
      }
    });
  }

  // === 数据加载 ===
  void _triggerInitialLoad() {
    if (_isVisible && !_isInitialized && !_isLoadingData) {
      _isInitialized = true;
      _loadActivities(isInitialLoad: true, pageToLoad: 1);
    }
  }

  Future<void> _loadActivities(
      {bool isInitialLoad = false,
      bool isRefresh = false,
      int pageToLoad = 1}) async {
    // --- 防止并发加载 ---
    if (_isLoadingData && !isRefresh) {
      return;
    }
    if (_isLoadingMore && isRefresh) {
      return;
    } // 刷新不能打断加载更多
    if (!mounted) return;

    // --- 停止/更新监听器 ---
    final String feedType = _getFeedType();
    final List<String>? types = _selectedType != null ? [_selectedType!] : null;
    final String newWatchIdentifier =
        "${feedType}_${widget.userId ?? 'none'}_${pageToLoad}_${types?.join('_') ?? 'all'}";
    if (_currentWatchIdentifier != newWatchIdentifier) {
      _stopWatchingCache(); // 停止监听旧的标识符
    }

    setState(() {
      _isLoadingData = true; // 开始加载
      _error = ''; // 清除错误
      if (isRefresh || isInitialLoad) {
        _currentPage = pageToLoad; // 确认目标页码
        if (isInitialLoad || _activities.isEmpty) {
          _activities = []; // 初始或列表为空时清空
        }
        _pagination = null;
      }
    });
    if (isRefresh && pageToLoad == 1) {
      _refreshAnimationController.forward(from: 0.0); // 只有刷新第一页才转圈
    }

    try {
      Map<String, dynamic> result;
      const int limit = 20; // 保持一致的 limit
      List<String>? currentTypes =
          _selectedType != null ? [_selectedType!] : null;
      final activityService = context.read<UserActivityService>();

      // --- 调用 Service 获取数据 (无节流，无 forceRefresh) ---
      if (feedType == 'user') {
        result = await activityService.getUserActivities(widget.userId!,
            page: pageToLoad, limit: limit, types: currentTypes);
      } else if (feedType == 'feed') {
        result = await activityService.getActivityFeed(
            page: pageToLoad, limit: limit);
      } else {
        result = await activityService.getPublicActivities(
            page: pageToLoad, limit: limit);
      }

      if (!mounted) return;

      final List<UserActivity> fetchedActivities = result['activities'] ?? [];
      final PaginationData? fetchedPagination = result['pagination'];

      if (fetchedActivities.isNotEmpty) {
        setState(() {
          _activities = fetchedActivities; // 替换为当前页数据
          _pagination = fetchedPagination;
          _currentPage = pageToLoad; // 确认当前页
          _isLoadingData = false; // 结束加载
          _error = ''; // 清除错误
          _lastRefreshTime = DateTime.now(); // 记录成功加载时间
        });
      } else {
        setState(() {
          _error = "发生错误无法获取数据";
          _isLoadingData = true; // 结束加载
        });
      }

      _startOrUpdateWatchingCache(); // 成功后启动/更新监听
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // 只在列表为空时显示全局错误
        if (_activities.isEmpty) {
          _error = '加载动态失败: $e';
        } else {
          AppSnackBar.showError(context, '刷新动态失败: $e'); // 否则用 Snackbar 提示
        }
        _isLoadingData = false; // 结束加载
        // 保持旧数据以便 UI 显示
      });
      _stopWatchingCache(); // 出错停止监听
    } finally {
      if (mounted && _isLoadingData) {
        setState(() => _isLoadingData = false);
      } // 最终确保结束加载
    }
  }

  // --- !!! 添加回 _refreshData 方法，用于下拉刷新 !!! ---
  /// 处理下拉刷新事件，强制加载第一页数据。
  Future<void> _refreshData() async {
    // UI 层防抖/节流 (与按钮点击逻辑类似)
    if (_isLoadingData || _isLoadingMore) return;
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!) < _minUiRefreshInterval) {
      await Future.delayed(Duration(milliseconds: 300)); // 给用户一个反馈
      return;
    }

    _stopWatchingCache(); // 停止旧监听
    setState(() {
      _currentPage = 1; // 重置到第一页
      _error = ''; // 清除错误
      // 不需要设置 isLoadingData，让 _loadActivities 处理
    });
    // --- 调用加载第一页的逻辑 ---
    // 标记为刷新，这样 _loadActivities 知道是刷新操作
    await _loadActivities(isRefresh: true, pageToLoad: 1);
  }
  // --- 结束添加 ---

  // --- !!! 修改 _handleRefreshButtonPress，调用 _refreshData !!! ---
  void _handleRefreshButtonPress() {
    // 直接调用统一的刷新方法，它内部包含了节流逻辑
    _refreshData();
  }

  Future<void> _loadMoreActivities() async {
    if (!_isInitialized ||
        _error.isNotEmpty ||
        _isLoadingData ||
        _isLoadingMore ||
        _pagination == null ||
        _currentPage >= _pagination!.pages) {
      return;
    }
    if (!mounted) return;
    final nextPage = _currentPage + 1;
    _stopWatchingCache(); // 停止监听旧页
    setState(() => _isLoadingMore = true);
    try {
      Map<String, dynamic> result;
      final activityService = context.read<UserActivityService>();
      const int limit = 20;
      List<String>? types = _selectedType != null ? [_selectedType!] : null;
      final String feedType = _getFeedType();
      if (feedType == 'user') {
        result = await activityService.getUserActivities(widget.userId!,
            page: nextPage, limit: limit, types: types);
      } else if (feedType == 'feed') {
        result =
            await activityService.getActivityFeed(page: nextPage, limit: limit);
      } else {
        result = await activityService.getPublicActivities(
            page: nextPage, limit: limit);
      }

      if (!mounted) return;
      final List<UserActivity> newActivities = result['activities'] ?? [];
      final PaginationData? newPagination = result['pagination'];
      setState(() {
        _activities.addAll(newActivities);
        _pagination = newPagination;
        _currentPage = nextPage;
        _isLoadingMore = false;
        _lastRefreshTime = DateTime.now(); // 加载更多成功也算一次刷新
      });
      _startOrUpdateWatchingCache(); // 监听新页
    } catch (e, s) {
      print(
          'ActivityFeedScreen (${widget.title}): Load more activities error: $e\n$s');
      if (mounted) {
        AppSnackBar.showError(context, '加载更多失败: $e');
        setState(() => _isLoadingMore = false);
      }
      _startOrUpdateWatchingCache(); // 失败后尝试重新监听之前的页
    } finally {
      if (mounted && _isLoadingMore) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _scrollListener() {
    if (_isInitialized && !_isLoadingMore && !_isLoadingData) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        _loadMoreActivities();
      }
    }
  }

  String _getFeedType() {
    if (widget.userId != null) return 'user';
    if (widget.title == '关注') return 'feed';
    return 'public';
  }

  void _onTypeFilterChanged(String? type) {
    if (_selectedType != type) {
      print(
          "ActivityFeedScreen (${widget.title}): Type filter changed to: $type");
      _stopWatchingCache();
      setState(() {
        _selectedType = type;
        _isInitialized = false;
        _isVisible = false;
        _activities = [];
        _error = '';
        _isLoadingData = false;
        _isLoadingMore = false;
        _currentPage = 1;
        _pagination = null;
        _currentWatchIdentifier = '';
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
      });
      // VisibilityDetector or manual trigger if needed
      if (_isVisible) _triggerInitialLoad(); // 如果仍然可见，尝试立即加载
    }
  }

  void _toggleLayoutMode() {
    setState(() => _useAlternatingLayout = !_useAlternatingLayout);
  }

  void _toggleHotActivitiesPanel() {
    setState(() => _showHotActivities = !_showHotActivities);
  }

  void _toggleCollapseMode() {
    setState(() => _collapseMode = FeedCollapseMode
        .values[(_collapseMode.index + 1) % FeedCollapseMode.values.length]);
  }

  String _getCollapseModeText() {
    switch (_collapseMode) {
      case FeedCollapseMode.none:
        return '标准视图';
      case FeedCollapseMode.byUser:
        return '按用户折叠';
      case FeedCollapseMode.byType:
        return '按类型折叠';
    }
  }

  IconData _getCollapseModeIcon() {
    switch (_collapseMode) {
      case FeedCollapseMode.none:
        return Icons.view_agenda;
      case FeedCollapseMode.byUser:
        return Icons.people_outline;
      case FeedCollapseMode.byType:
        return Icons.category_outlined;
    }
  }

  void _navigateToActivityDetail(UserActivity activity) {
    _stopWatchingCache();
    NavigationUtils.pushNamed(context, AppRoutes.activityDetail,
        arguments: {'activityId': activity.id, 'activity': activity}).then((_) {
      if (mounted) {
        _startOrUpdateWatchingCache();
        _refreshCurrentPageData(reason: "Returned from Detail");
      }
    });
  }

  // --- 新增：传递给 CollapsibleActivityFeed 的具体回调实现 ---

  Future<void> _handleDeleteActivity(String activityId) async {
    await CustomConfirmDialog.show(
      context: context,
      title: "确认删除",
      message: "确定删除这条动态吗？",
      confirmButtonText: "删除",
      confirmButtonColor: Colors.red,
      iconData: Icons.delete_outline,
      iconColor: Colors.red,
      onConfirm: () async {
        print("Delete confirmed for $activityId");
        try {
          final activityService = context.read<UserActivityService>();
          final success = await activityService.deleteActivity(activityId);
          if (success && mounted) AppSnackBar.showSuccess(context, '动态已删除');
          // 刷新由监听器处理
        } catch (e) {
          if (mounted) AppSnackBar.showError(context, '删除失败: $e');
          rethrow;
        }
      },
    );
  }

  Future<void> _handleLikeActivity(String activityId) async {
    try {
      final activityService = context.read<UserActivityService>();
      await activityService.likeActivity(activityId);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '点赞失败: $e'); /* 回滚补偿 */
    }
  }

  Future<void> _handleUnlikeActivity(String activityId) async {
    try {
      final activityService = context.read<UserActivityService>();
      await activityService.unlikeActivity(activityId);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '取消点赞失败: $e'); /* 回滚补偿 */
    }
  }

  Future<ActivityComment?> _handleAddComment(
      String activityId, String content) async {
    try {
      final activityService = context.read<UserActivityService>();
      final comment =
          await activityService.commentOnActivity(activityId, content);
      if (comment != null && mounted) {
        AppSnackBar.showSuccess(context, '评论成功');
        // 刷新由监听器处理
        return comment; // 返回新评论，如果 Card 需要的话
      } else if (mounted) {
        throw Exception("未能添加评论");
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '评论失败: $e');
    }
    return null;
  }

  Future<void> _handleDeleteComment(String activityId, String commentId) async {
    print("Requesting delete comment $commentId from activity $activityId");
    await CustomConfirmDialog.show(
      context: context,
      title: "确认删除",
      message: "确定删除这条评论吗？",
      confirmButtonText: "删除",
      confirmButtonColor: Colors.red,
      iconData: Icons.delete_outline,
      iconColor: Colors.red,
      onConfirm: () async {
        print("Delete comment confirmed for $commentId");
        try {
          final activityService = context.read<UserActivityService>();
          final success =
              await activityService.deleteComment(activityId, commentId);
          if (success && mounted) AppSnackBar.showSuccess(context, '评论已删除');
          // 刷新由监听器处理
        } catch (e) {
          if (mounted) AppSnackBar.showError(context, '删除评论失败: $e');
          rethrow;
        }
      },
    );
  }

  Future<void> _handleLikeComment(String activityId, String commentId) async {
    // 前端补偿在 ActivityCommentItem 内部处理
    try {
      final activityService = context.read<UserActivityService>();
      await activityService.likeComment(activityId, commentId);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '点赞评论失败: $e');
    }
  }

  Future<void> _handleUnlikeComment(String activityId, String commentId) async {
    // 前端补偿在 ActivityCommentItem 内部处理
    try {
      final activityService = context.read<UserActivityService>();
      await activityService.unlikeComment(activityId, commentId);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '取消点赞评论失败: $e');
    }
  }

  // === 构建 UI ===
  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(
          'activity_feed_visibility_${widget.key?.toString() ?? widget.title}'),
      onVisibilityChanged: (VisibilityInfo info) {
        final bool currentlyVisible = info.visibleFraction > 0.8;
        if (currentlyVisible != _isVisible) {
          final bool wasVisible = _isVisible;
          _isVisible = currentlyVisible;
          if (mounted) setState(() {});
          if (_isVisible) {
            _triggerInitialLoad();
            _startOrUpdateWatchingCache();
            if (!wasVisible) _refreshCurrentPageData(reason: "Became Visible");
          } else {
            _stopWatchingCache();
          }
        }
      },
      child: Scaffold(
        //appBar: CustomAppBar(title: "动态空间"),
        body: SafeArea(child: _buildBodyContent()),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (!_isInitialized && !_isLoadingData) {
      return LoadingWidget.fullScreen(message: "等待加载动态...");
    }
    if (_isLoadingData && _activities.isEmpty) {
      return LoadingWidget.fullScreen(message: "正在加载动态...");
    }
    if (_error.isNotEmpty && _activities.isEmpty) {
      return CustomErrorWidget(
          errorMessage: _error,
          onRetry: () => _loadActivities(isRefresh: true, pageToLoad: 1));
    }

    return Column(
      children: [
        // Top Action Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                  child: InkWell(
                      onTap: _toggleCollapseMode,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.3))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_getCollapseModeIcon(),
                                size: 16,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(_getCollapseModeText(),
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold))
                          ])))),
              const SizedBox(width: 8),
              RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0)
                      .animate(_refreshAnimationController),
                  child: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: (_isLoadingData || _isLoadingMore)
                          ? null
                          : _handleRefreshButtonPress,
                      tooltip: '刷新')), // 使用带节流的按钮处理
              IconButton(
                  icon: Icon(_useAlternatingLayout
                      ? Icons.view_stream_outlined
                      : Icons.chat_bubble_outline),
                  onPressed: _toggleLayoutMode,
                  tooltip: _useAlternatingLayout ? '标准布局' : '气泡布局'),
              IconButton(
                  icon: Icon(_showHotActivities
                      ? Icons.visibility_off_outlined
                      : Icons.local_fire_department_outlined),
                  onPressed: _toggleHotActivitiesPanel,
                  tooltip: _showHotActivities ? '隐藏热门' : '显示热门'),
            ],
          ),
        ),
        // Main Content Area
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side
              Expanded(
                child: Column(
                  children: [
                    if (widget.userId != null)
                      ActivityTypeFilter(
                          selectedType: _selectedType,
                          onTypeSelected: _onTypeFilterChanged),
                    // Activity Feed
                    Expanded(
                      child: CollapsibleActivityFeed(
                        key: ValueKey(
                            'feed_${widget.userId}_${_selectedType}_${_collapseMode.index}'),
                        activities: _activities,
                        isLoading: _isLoadingData && _activities.isEmpty,
                        isLoadingMore: _isLoadingMore,
                        error: _error.isNotEmpty && _activities.isEmpty
                            ? _error
                            : '',
                        collapseMode: _collapseMode,
                        useAlternatingLayout: _useAlternatingLayout,
                        onActivityTap: _navigateToActivityDetail,
                        onRefresh: _refreshData, // 传递给 RefreshIndicator
                        onLoadMore: _loadMoreActivities,
                        scrollController: _scrollController,
                        onDeleteActivity: _handleDeleteActivity,
                        onLikeActivity: _handleLikeActivity,
                        onUnlikeActivity: _handleUnlikeActivity,
                        onAddComment: _handleAddComment,
                        onDeleteComment: _handleDeleteComment,
                        onLikeComment: _handleLikeComment,
                        onUnlikeComment: _handleUnlikeComment,
                        onEditActivity: null, // 示例
                      ),
                    ),
                  ],
                ),
              ),
              // Right Side
              if (_showHotActivities) const HotActivitiesPanel(),
            ],
          ),
        ),
      ],
    );
  }
} // _ActivityFeedScreenState 类结束

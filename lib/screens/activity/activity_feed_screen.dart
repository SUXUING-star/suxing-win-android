// lib/screens/activity/activity_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_type_filter.dart';
import 'package:suxingchahui/widgets/components/screen/activity/panel/hot_activities_panel.dart';
import 'package:suxingchahui/widgets/components/screen/activity/feed/collapsible_activity_feed.dart';

class ActivityFeedScreen extends StatefulWidget {
  final String? userId; // 可选用户ID，如果提供则显示该用户的动态
  final String? type; // 可选动态类型过滤
  final String title; // 屏幕标题
  final bool useAlternatingLayout; // 是否使用交替布局
  final bool showHotActivities; // 是否显示热门动态面板

  const ActivityFeedScreen({
    Key? key,
    this.userId,
    this.type,
    this.title = '动态流',
    this.useAlternatingLayout = true, // 默认使用交替布局
    this.showHotActivities = true, // 默认显示热门动态
  }) : super(key: key);

  @override
  _ActivityFeedScreenState createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen>
    with SingleTickerProviderStateMixin {
  final UserActivityService _activityService = UserActivityService();
  final ScrollController _scrollController = ScrollController();

  List<UserActivity> _activities = [];
  PaginationData? _pagination;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _error = '';
  int _currentPage = 1;
  String? _selectedType; // 当前选择的过滤类型
  bool _useAlternatingLayout = true; // 是否使用交替布局
  bool _showHotActivities = true; // 是否显示热门动态面板

  // 新增：折叠模式
  FeedCollapseMode _collapseMode = FeedCollapseMode.none;

  // 动画控制器
  late AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _useAlternatingLayout = widget.useAlternatingLayout;
    _showHotActivities = widget.showHotActivities;
    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _loadActivities();

    // 添加滚动监听器用于分页加载
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  // 滚动监听器，用于触发加载更多
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMoreActivities();
    }
  }

  // 处理类型过滤变化
  void _onTypeFilterChanged(String? type) {
    if (_selectedType != type) {
      setState(() {
        _selectedType = type;
        _currentPage = 1;
      });
      _loadActivities();
    }
  }

  // 切换布局模式
  void _toggleLayoutMode() {
    setState(() {
      _useAlternatingLayout = !_useAlternatingLayout;
    });
  }

  // 切换热门动态面板显示
  void _toggleHotActivitiesPanel() {
    setState(() {
      _showHotActivities = !_showHotActivities;
    });
  }

  // 新增：切换折叠模式
  void _toggleCollapseMode() {
    setState(() {
      switch (_collapseMode) {
        case FeedCollapseMode.none:
          _collapseMode = FeedCollapseMode.byUser;
          break;
        case FeedCollapseMode.byUser:
          _collapseMode = FeedCollapseMode.byType;
          break;
        case FeedCollapseMode.byType:
          _collapseMode = FeedCollapseMode.none;
          break;
      }
    });
  }

  // 加载活动数据
  Future<void> _loadActivities() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 1;
    });

    // 开始刷新动画
    _refreshAnimationController.forward(from: 0.0);

    try {
      Map<String, dynamic> result;

      if (widget.userId != null) {
        // 加载特定用户的动态
        List<String>? types;
        if (_selectedType != null) {
          types = [_selectedType!];
        } else if (widget.type != null) {
          types = [widget.type!];
        }

        result = await _activityService.getUserActivities(
          widget.userId!,
          page: _currentPage,
          limit: 20,
          types: types,
        );
      } else {
        // 加载公开动态流
        result = await _activityService.getPublicActivities(
          page: _currentPage,
          limit: 20,
        );
      }

      setState(() {
        _activities = result['activities'];
        _pagination = result['pagination'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  // 加载更多活动数据
  Future<void> _loadMoreActivities() async {
    if (_isLoading || _isLoadingMore) return;
    if (_pagination == null || _currentPage >= _pagination!.pages) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      Map<String, dynamic> result;

      if (widget.userId != null) {
        // 加载特定用户的更多动态
        List<String>? types;
        if (_selectedType != null) {
          types = [_selectedType!];
        } else if (widget.type != null) {
          types = [widget.type!];
        }

        result = await _activityService.getUserActivities(
          widget.userId!,
          page: nextPage,
          limit: 20,
          types: types,
        );
      } else {
        // 加载更多公开动态
        result = await _activityService.getPublicActivities(
          page: nextPage,
          limit: 20,
        );
      }

      final List<UserActivity> newActivities = result['activities'];

      setState(() {
        _activities.addAll(newActivities);
        _pagination = result['pagination'];
        _currentPage = nextPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _error = '加载更多失败: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载更多内容失败: $e')),
        );
      }
    }
  }

  // 当活动项被更新时调用
  void _onActivityUpdated() {
    // 在实际应用中可能需要重新加载特定活动或更新其状态
  }

  // 导航到活动详情页
  void _navigateToActivityDetail(UserActivity activity) {
    Navigator.pushNamed(
      context,
      '/activity/detail',
      arguments: {
        'activityId': activity.id,
        'activity': activity,
      },
    );
  }

  // 获取当前折叠模式的显示文本
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

  // 获取当前折叠模式的图标
  IconData _getCollapseModeIcon() {
    switch (_collapseMode) {
      case FeedCollapseMode.none:
        return Icons.view_agenda;
      case FeedCollapseMode.byUser:
        return Icons.people;
      case FeedCollapseMode.byType:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部操作栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  // 新增：折叠模式切换按钮
                  Expanded(
                    child: InkWell(
                      onTap: _toggleCollapseMode,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCollapseModeIcon(),
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getCollapseModeText(),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 刷新按钮
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 1.0)
                        .animate(_refreshAnimationController),
                    child: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadActivities,
                      tooltip: '刷新',
                    ),
                  ),
                  // 布局切换按钮
                  IconButton(
                    icon: Icon(
                      _useAlternatingLayout
                          ? Icons.chat_bubble_outline
                          : Icons.view_stream,
                    ),
                    onPressed: _toggleLayoutMode,
                    tooltip: _useAlternatingLayout ? '切换到标准布局' : '切换到聊天气泡布局',
                  ),
                  // 热门动态显示切换
                  IconButton(
                    icon: Icon(
                      _showHotActivities ? Icons.view_sidebar : Icons.view_agenda,
                    ),
                    onPressed: _toggleHotActivitiesPanel,
                    tooltip: _showHotActivities ? '隐藏热门动态' : '显示热门动态',
                  ),
                ],
              ),
            ),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 主内容区域
                  Expanded(
                    child: Column(
                      children: [
                        // 类型过滤器（仅在用户配置文件页面上显示）
                        if (widget.userId != null)
                          ActivityTypeFilter(
                            selectedType: _selectedType,
                            onTypeSelected: _onTypeFilterChanged,
                          ),

                        // 使用新的可折叠活动Feed组件
                        Expanded(
                          child: CollapsibleActivityFeed(
                            activities: _activities,
                            isLoading: _isLoading,
                            isLoadingMore: _isLoadingMore,
                            error: _error,
                            collapseMode: _collapseMode,
                            useAlternatingLayout: _useAlternatingLayout,
                            onActivityTap: _navigateToActivityDetail,
                            onRefresh: _loadActivities,
                            onLoadMore: _loadMoreActivities,
                            scrollController: _scrollController,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 热门动态面板（可显示/隐藏）
                  if (_showHotActivities) const HotActivitiesPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
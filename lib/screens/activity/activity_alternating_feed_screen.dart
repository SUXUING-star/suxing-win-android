// lib/screens/activity/activity_alternating_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/common/pagination.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_card.dart';
import 'package:suxingchahui/widgets/components/screen/activity/common/activity_empty_state.dart';
import 'package:suxingchahui/widgets/components/screen/activity/card/activity_type_filter.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';

class ActivityAlternatingFeedScreen extends StatefulWidget {
  final String? userId; // 可选用户ID，如果提供则显示该用户的动态
  final String title; // 屏幕标题

  const ActivityAlternatingFeedScreen({
    Key? key,
    this.userId,
    this.title = '我的动态',
  }) : super(key: key);

  @override
  _ActivityAlternatingFeedScreenState createState() => _ActivityAlternatingFeedScreenState();
}

class _ActivityAlternatingFeedScreenState extends State<ActivityAlternatingFeedScreen> {
  final UserActivityService _activityService = UserActivityService();
  final ScrollController _scrollController = ScrollController();

  List<UserActivity> _activities = [];
  PaginationData? _pagination;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _error = '';
  int _currentPage = 1;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadActivities();

    // 添加滚动监听器用于分页加载
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // 滚动监听器，用于触发加载更多
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreActivities();
    }
  }

  // 当活动类型过滤器改变时
  void _onTypeFilterChanged(String? type) {
    if (_selectedType != type) {
      setState(() {
        _selectedType = type;
        _currentPage = 1;
      });
      _loadActivities();
    }
  }

  // 根据不同情况加载活动数据
  Future<void> _loadActivities() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = '';
      _currentPage = 1;
    });

    try {
      Map<String, dynamic> result;

      if (widget.userId != null) {
        // 加载特定用户的动态
        List<String>? types;
        if (_selectedType != null) {
          types = [_selectedType!];
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
      });
    }
  }

  // 当活动项被更新时调用
  void _onActivityUpdated() {
    // 在实际应用中可能需要重新加载特定活动或更新其状态
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _activities.isEmpty) {
      return LoadingWidget.inline();
    }

    if (_error.isNotEmpty && _activities.isEmpty) {
      return ActivityEmptyState(
        message: _error,
        icon: Icons.error_outline,
        onRefresh: _loadActivities,
      );
    }

    return Column(
      children: [
        // 类型过滤器
        if (widget.userId != null) // 只在用户个人页面显示过滤器
          ActivityTypeFilter(
            selectedType: _selectedType,
            onTypeSelected: _onTypeFilterChanged,
          ),

        // 动态列表
        Expanded(
          child: _activities.isEmpty
              ? const ActivityEmptyState(
            message: '暂无动态内容',
            icon: Icons.feed_outlined,
          )
              : RefreshIndicator(
            onRefresh: _loadActivities,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _activities.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // 显示加载更多指示器
                if (index == _activities.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // 获取活动项
                final activity = _activities[index];

                // 左右交替显示
                final bool isAlternate = index % 2 == 1;

                return ActivityCard(
                  activity: activity,
                  isAlternate: isAlternate,
                  onUpdated: _onActivityUpdated,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
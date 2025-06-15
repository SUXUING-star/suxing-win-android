// lib/widgets/components/screen/activity/panel/hot_activities_panel.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/activity/activity_constants.dart';
import 'package:suxingchahui/models/activity/activity_stats.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'hot_activities_full_panel.dart';

class HotActivitiesPanel extends StatefulWidget {
  final User? currentUser;
  final double screenWidth;
  final UserInfoProvider userInfoProvider;
  final ActivityService activityService;
  final UserFollowService followService;
  const HotActivitiesPanel({
    required this.currentUser,
    required this.screenWidth,
    required this.activityService,
    required this.userInfoProvider,
    required this.followService,
    super.key,
  });

  @override
  _HotActivitiesPanelState createState() => _HotActivitiesPanelState();
}

class _HotActivitiesPanelState extends State<HotActivitiesPanel>
    with AutomaticKeepAliveClientMixin {
  List<UserActivity> _hotActivities = [];
  ActivityStats _activityStats = ActivityStats.empty();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  User? _currentUser;

  @override
  bool get wantKeepAlive => true;

  bool _hasInitializedDependencies = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _currentUser = widget.currentUser;
      _loadData();
    }
  }

  @override
  void didUpdateWidget(covariant HotActivitiesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser != widget.currentUser ||
        _currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
  }

  // 加载热门动态和统计数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final hotActivities = await widget.activityService.getHotActivities();
      final typeStats = await widget.activityService.getActivityTypeStats();

      if (mounted) {
        setState(() {
          _hotActivities = hotActivities;
          _activityStats = typeStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '加载数据失败: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 响应式宽度
    final panelWidth =
        widget.screenWidth < 600 ? widget.screenWidth * 0.9 : 300.0;

    return HotActivitiesFullPanel(
      userInfoProvider: widget.userInfoProvider,
      userFollowService: widget.followService,
      currentUser: widget.currentUser,
      hotActivities: _hotActivities,
      activityStats: _activityStats,
      isLoading: _isLoading,
      hasError: _hasError,
      errorMessage: _errorMessage,
      onRefresh: _loadData,
      getActivityTypeName: ActivityTypeUtils.getActivityTypeText,
      getActivityTypeColor: ActivityTypeUtils.getActivityTypeBackgroundColor,
      panelWidth: panelWidth,
    );
  }
}

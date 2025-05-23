// lib/widgets/components/screen/activity/hot_activities_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/constants/activity/activity_constants.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'layout/desktop/hot_activities_full_panel.dart';

class HotActivitiesPanel extends StatefulWidget {
  final User? currentUser;
  final UserInfoProvider userInfoProvider;
  final UserActivityService activityService;
  final UserFollowService followService;
  const HotActivitiesPanel({
    required this.currentUser,
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
  Map<String, int> _activityStats = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  bool get wantKeepAlive => true;

  bool _hasInitializedDependencies = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _loadData();
    }
  }

  // 加载热门动态和统计数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // 并行加载数据
      final results = await Future.wait([
        widget.activityService.getHotActivities(),
        widget.activityService.getActivityTypeStats(),
      ]);

      if (mounted) {
        setState(() {
          _hotActivities = results[0] as List<UserActivity>;
          _activityStats = results[1] as Map<String, int>;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth < 600 ? screenWidth * 0.9 : 300.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 默认完整面板
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
          getActivityTypeColor:
              ActivityTypeUtils.getActivityTypeBackgroundColor,
          panelWidth: panelWidth,
        );
      },
    );
  }
}

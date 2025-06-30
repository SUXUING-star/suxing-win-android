// lib/widgets/components/screen/activity/panel/layout/desktop/hot_activities_full_panel.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/activity_stats.dart';
import 'package:suxingchahui/models/activity/activity.dart';
import 'package:suxingchahui/models/user/user/user.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'stats/activity_stats_card.dart';
import 'stats/hot_activities_list.dart';

class HotActivitiesFullPanel extends StatelessWidget {
  final UserFollowService userFollowService;
  final UserInfoService userInfoService;
  final List<Activity> hotActivities;
  final User? currentUser;
  final ActivityStats activityStats;
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final VoidCallback onRefresh;
  final double panelWidth;

  const HotActivitiesFullPanel({
    super.key,
    required this.userFollowService,
    required this.userInfoService,
    required this.hotActivities,
    required this.currentUser,
    required this.activityStats,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.onRefresh,
    required this.panelWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: panelWidth,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和刷新按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        '热门动态',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: '刷新数据',
                  ),
                ],
              ),
              const Divider(),

              // 统计卡片部分
              ActivityStatsCard(
                activityStats: activityStats,
                isLoading: isLoading,
              ),

              const SizedBox(height: 16),

              // 热门动态列表
              Expanded(
                child: isLoading
                    ? const LoadingWidget(
                        size: 12,
                      )
                    : hasError
                        ? Center(child: Text(errorMessage))
                        : HotActivitiesList(
                            userFollowService: userFollowService,
                            userInfoService: userInfoService,
                            currentUser: currentUser,
                            hotActivities: hotActivities,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

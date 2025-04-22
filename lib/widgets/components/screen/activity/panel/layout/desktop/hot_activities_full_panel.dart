// lib/widgets/components/screen/activity/hot_activities_full_panel.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import '../../stats/activity_stats_card.dart';
import '../../stats/hot_activities_list.dart';

class HotActivitiesFullPanel extends StatelessWidget {
  final List<UserActivity> hotActivities;
  final Map<String, int> activityStats;
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final VoidCallback onRefresh;
  final String Function(String) getActivityTypeName;
  final Color Function(String) getActivityTypeColor;
  final double panelWidth;

  const HotActivitiesFullPanel({
    super.key,
    required this.hotActivities,
    required this.activityStats,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.onRefresh,
    required this.getActivityTypeName,
    required this.getActivityTypeColor,
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
                      Icon(Icons.local_fire_department, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        '热门动态',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: '刷新数据',
                  ),
                ],
              ),
              Divider(),

              // 统计卡片部分
              ActivityStatsCard(
                activityStats: activityStats,
                isLoading: isLoading,
                getActivityTypeName: getActivityTypeName,
                getActivityTypeColor: getActivityTypeColor,
              ),

              SizedBox(height: 16),

              // 热门动态列表
              Expanded(
                child: isLoading
                    ? LoadingWidget.inline(size: 12,)
                    : hasError
                    ? Center(child: Text(errorMessage))
                    : HotActivitiesList(
                  hotActivities: hotActivities,
                  getActivityTypeName: getActivityTypeName,
                  getActivityTypeColor: getActivityTypeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
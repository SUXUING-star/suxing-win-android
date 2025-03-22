// lib/widgets/components/screen/activity/hot_activities_compact_panel.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/screens/profile/open_profile_screen.dart';
import '../../../utils/activity_utils.dart';

class HotActivitiesCompactPanel extends StatelessWidget {
  final List<UserActivity> hotActivities;
  final Map<String, int> activityStats;
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final VoidCallback onRefresh;
  final String Function(String) getActivityTypeName;
  final Color Function(String) getActivityTypeColor;
  final double panelWidth;

  const HotActivitiesCompactPanel({
    Key? key,
    required this.hotActivities,
    required this.activityStats,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.onRefresh,
    required this.getActivityTypeName,
    required this.getActivityTypeColor,
    required this.panelWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: panelWidth,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
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
            ),
            Divider(),

            // 简化的统计信息
            _buildCompactStatsCards(),

            // 紧凑的活动列表
            _buildCompactActivitiesList(context),
          ],
        ),
      ),
    );
  }

  // 紧凑型统计卡片
  Widget _buildCompactStatsCards() {
    final totalActivities = activityStats['totalActivities'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '总动态数: $totalActivities',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          // 可以添加一个小的活动类型标签
          _buildMiniActivityTypeTag(),
        ],
      ),
    );
  }

  // 生成一个小型活动类型标签
  Widget _buildMiniActivityTypeTag() {
    // 获取出现次数最多的活动类型
    final topType = activityStats.entries
        .where((entry) => entry.key != 'totalActivities')
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    final typeName = getActivityTypeName(topType);
    final typeColor = getActivityTypeColor(topType);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: typeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        typeName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 紧凑的活动列表
  Widget _buildCompactActivitiesList(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(errorMessage),
      );
    }

    if (hotActivities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text('暂无热门动态'),
      );
    }

    return Column(
      children: hotActivities.map((activity) {
        final username = activity.user?['username'] ?? '未知用户';
        final activityDescription = ActivityUtils.getActivityDescription(activity);

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: activity.user?['avatar'] != null
                ? NetworkImage(activity.user?['avatar'])
                : null,
            child: activity.user?['avatar'] == null
                ? Text(username[0].toUpperCase())
                : null,
          ),
          title: Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
              activityDescription,
              maxLines: 1,
              overflow: TextOverflow.ellipsis
          ),
          onTap: () => _navigateToUserProfile(context, activity.userId),
        );
      }).toList(),
    );
  }

  void _navigateToUserProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenProfileScreen(userId: userId),
      ),
    );
  }
}
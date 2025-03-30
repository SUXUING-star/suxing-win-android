// lib/widgets/components/screen/activity/hot_activities_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/screens/profile/open_profile_screen.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../utils/activity_utils.dart';

class HotActivitiesList extends StatelessWidget {
  final List<UserActivity> hotActivities;
  final String Function(String) getActivityTypeName;
  final Color Function(String) getActivityTypeColor;

  const HotActivitiesList({
    Key? key,
    required this.hotActivities,
    required this.getActivityTypeName,
    required this.getActivityTypeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (hotActivities.isEmpty) {
      return Center(child: Text('暂无热门动态'));
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.only(top: 8),
        itemCount: hotActivities.length,
        itemBuilder: (context, index) {
          final activity = hotActivities[index];

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildHotActivityItem(context, activity, index),
              ),
            ),
          );
        },
      ),
    );
  }

  // 构建单个热门动态项
  Widget _buildHotActivityItem(BuildContext context, UserActivity activity, int index) {
    final username = activity.user?['username'] ?? '未知用户';
    final avatarUrl = activity.user?['avatar'];

    String activityTitle = ActivityUtils.getActivityDescription(activity);
    final typeColor = getActivityTypeColor(activity.type);

    return Card(
      elevation: 0,
      color: index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          NavigationUtils.pushNamed(
              context,
              AppRoutes.activityDetail,
              arguments: activity.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 用户信息
              Row(
                children: [
                  InkWell(
                    onTap: () => _navigateToUserProfile(context, activity.userId),
                    child: CircleAvatar(
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null ? Text(username[0].toUpperCase()) : null,
                      radius: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          activityTitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 活动内容
              if (activity.content.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  activity.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // 活动统计
              SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, size: 14),
                        SizedBox(width: 4),
                        Text('${activity.likesCount}'),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.comment, size: 14),
                        SizedBox(width: 4),
                        Text('${activity.commentsCount}'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUserProfile(BuildContext context, String userId) {
    NavigationUtils.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenProfileScreen(userId: userId),
      ),
    );
  }
}
// lib/widgets/components/screen/activity/hot_activities_panel.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/services/main/activity/activity_service.dart';
import 'package:suxingchahui/screens/profile/open_profile_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:math' as math;

class HotActivitiesPanel extends StatefulWidget {
  const HotActivitiesPanel({Key? key}) : super(key: key);

  @override
  _HotActivitiesPanelState createState() => _HotActivitiesPanelState();
}

class _HotActivitiesPanelState extends State<HotActivitiesPanel> with AutomaticKeepAliveClientMixin {
  final UserActivityService _activityService = UserActivityService();
  List<UserActivity> _hotActivities = [];
  Map<String, int> _activityStats = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
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
        _activityService.getHotActivities(limit: 5),
        _activityService.getActivityTypeStats(),
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

  // 解析活动类型为中文名称
  String _getActivityTypeName(String type) {
    switch (type) {
      case 'game_comment':
        return '游戏评论';
      case 'game_like':
        return '游戏点赞';
      case 'collection':
        return '游戏收藏';
      case 'post_reply':
        return '帖子回复';
      case 'follow':
        return '用户关注';
      case 'check_in':
        return '每日签到';
      default:
        return '其他活动';
    }
  }

  // 获取活动类型对应的颜色
  Color _getActivityTypeColor(String type) {
    switch (type) {
      case 'gameComment':
        return Colors.blue.shade200;
      case 'gameLike':
        return Colors.pink.shade200;
      case 'gameCollection':
        return Colors.amber.shade200;
      case 'postReply':
        return Colors.green.shade200;
      case 'userFollow':
        return Colors.purple.shade200;
      case 'checkIn':
        return Colors.teal.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  // 导航到用户个人资料页
  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      width: 300,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    onPressed: _loadData,
                    tooltip: '刷新数据',
                  ),
                ],
              ),
              Divider(),

              // 统计卡片部分
              _buildStatsCards(),

              SizedBox(height: 16),

              // 热门动态列表
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _hasError
                    ? Center(child: Text(_errorMessage))
                    : _buildHotActivitiesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建统计卡片
  Widget _buildStatsCards() {
    if (_isLoading) {
      return Container(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _activityStats.isEmpty) {
      return Container(
        height: 80,
        child: Center(child: Text('无法加载统计数据')),
      );
    }

    // 提取主要统计数据
    final totalActivities = _activityStats['totalActivities'] ?? 0;

    // 按照数量排序获取前三种类型的活动
    final typeCounts = <String, int>{};
    _activityStats.forEach((key, value) {
      if (key != 'totalActivities') {
        typeCounts[key] = value;
      }
    });

    final sortedTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        // 总动态数
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue.shade700),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '总动态数',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$totalActivities 条',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 8),

        // 动态类型分布
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: math.min(3, sortedTypes.length),
            itemBuilder: (context, index) {
              final type = sortedTypes[index].key;
              final count = sortedTypes[index].value;
              final typeName = _getActivityTypeName(type);
              final color = _getActivityTypeColor(type);

              return Container(
                width: 90,
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      typeName,
                      style: TextStyle(
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 构建热门动态列表
  Widget _buildHotActivitiesList() {
    if (_hotActivities.isEmpty) {
      return Center(child: Text('暂无热门动态'));
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.only(top: 8),
        itemCount: _hotActivities.length,
        itemBuilder: (context, index) {
          final activity = _hotActivities[index];

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildHotActivityItem(activity, index),
              ),
            ),
          );
        },
      ),
    );
  }

  // 构建单个热门动态项
  Widget _buildHotActivityItem(UserActivity activity, int index) {
    final username = activity.user?['username'] ?? '未知用户';
    final avatarUrl = activity.user?['avatar'];

    String activityTitle = '';

    switch (activity.type) {
      case 'game_comment':
        final gameName = activity.target?['title'] ?? '未知游戏';
        activityTitle = '评论了游戏 $gameName';
        break;
      case 'game_like':
        final gameName = activity.target?['title'] ?? '未知游戏';
        activityTitle = '点赞了游戏 $gameName';
        break;
      case 'game_collection':
        final gameName = activity.target?['title'] ?? '未知游戏';
        activityTitle = '收藏了游戏 $gameName';
        break;
      case 'post_reply':
        final postTitle = activity.target?['title'] ?? '未知帖子';
        activityTitle = '回复了帖子 $postTitle';
        break;
      case 'user_follow':
        final targetName = activity.target?['username'] ?? '未知用户';
        activityTitle = '关注了用户 $targetName';
        break;
      case 'check_in':
        activityTitle = '完成了签到';
        break;
      default:
        activityTitle = '发布了动态';
    }

    final typeColor = _getActivityTypeColor(activity.type);

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
          // 可以添加点击查看详情的操作
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
                    onTap: () => _navigateToUserProfile(activity.userId),
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
}
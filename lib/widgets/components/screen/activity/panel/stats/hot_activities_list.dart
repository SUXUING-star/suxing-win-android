// lib/widgets/components/screen/activity/panel/stats/hot_activities_list.dart

/// 该文件定义了 HotActivitiesList 组件，用于显示热门动态列表。
/// HotActivitiesList 展示热门用户动态，包含用户、内容和统计信息。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // 错列动画库
import 'package:suxingchahui/models/activity/user_activity.dart'; // 用户动态模型
import 'package:suxingchahui/models/user/user.dart'; // 用户模型
import 'package:suxingchahui/providers/user/user_info_provider.dart'; // 用户信息 Provider
import 'package:suxingchahui/routes/app_routes.dart'; // 应用路由
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 用户信息徽章组件

/// `HotActivitiesList` 类：热门动态列表组件。
///
/// 该组件以列表形式展示热门用户动态，支持动画效果。
class HotActivitiesList extends StatelessWidget {
  final List<UserActivity> hotActivities; // 热门动态列表
  final User? currentUser; // 当前登录用户
  final UserFollowService userFollowService; // 用户关注服务
  final UserInfoProvider userInfoProvider; // 用户信息 Provider
  final String Function(String) getActivityTypeName; // 获取活动类型名称的函数
  final Color Function(String) getActivityTypeColor; // 获取活动类型颜色的函数

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [currentUser]：当前登录用户。
  /// [userFollowService]：用户关注服务。
  /// [userInfoProvider]：用户信息 Provider。
  /// [hotActivities]：热门动态列表。
  /// [getActivityTypeName]：获取活动类型名称的函数。
  /// [getActivityTypeColor]：获取活动类型颜色的函数。
  const HotActivitiesList({
    super.key,
    required this.currentUser,
    required this.userFollowService,
    required this.userInfoProvider,
    required this.hotActivities,
    required this.getActivityTypeName,
    required this.getActivityTypeColor,
  });

  /// 构建 Widget。
  ///
  /// 如果热门动态列表为空，显示提示信息。
  /// 否则，使用动画列表构建热门动态项。
  @override
  Widget build(BuildContext context) {
    if (hotActivities.isEmpty) {
      // 列表为空时
      return Center(child: Text('暂无热门动态')); // 显示提示文本
    }

    return AnimationLimiter(
      // 动画限制器
      child: ListView.builder(
        padding: EdgeInsets.only(top: 8), // 顶部内边距
        itemCount: hotActivities.length, // 列表项数量
        itemBuilder: (context, index) {
          final activity = hotActivities[index]; // 获取当前动态
          return AnimationConfiguration.staggeredList(
            // 错列列表动画配置
            position: index, // 列表项位置
            duration: const Duration(milliseconds: 375), // 动画时长
            child: SlideAnimation(
              // 滑动动画
              verticalOffset: 50.0, // 垂直偏移量
              child: FadeInAnimation(
                // 淡入动画
                child: _buildHotActivityItem(
                    context, activity, index), // 构建单个热门动态项
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建单个热门动态项。
  ///
  /// [context]：Build 上下文。
  /// [activity]：要构建的动态数据。
  /// [index]：列表项索引。
  /// 返回一个包含动态信息和统计的 Card Widget。
  Widget _buildHotActivityItem(
      BuildContext context, UserActivity activity, int index) {
    final typeColor = getActivityTypeColor(activity.type); // 获取活动类型颜色

    return Card(
      elevation: 0, // 无阴影
      color: index % 2 == 0 ? Colors.grey.shade50 : Colors.white, // 根据索引设置背景色
      margin: EdgeInsets.only(bottom: 8), // 底部外边距
      shape: RoundedRectangleBorder(
        // 圆角边框
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200), // 边框
      ),
      child: InkWell(
        // 可点击区域
        onTap: () {
          // 点击回调
          NavigationUtils.pushNamed(
              context, AppRoutes.activityDetail, // 导航到动态详情页
              arguments: activity.id); // 传递动态 ID
        },
        borderRadius: BorderRadius.circular(12), // 点击区域圆角
        child: Padding(
          padding: const EdgeInsets.all(12.0), // 内边距
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴对齐
            children: [
              Row(
                children: [
                  UserInfoBadge(
                    // 用户信息徽章
                    followService: userFollowService, // 用户关注服务
                    infoProvider: userInfoProvider, // 用户信息 Provider
                    currentUser: currentUser, // 当前登录用户
                    targetUserId: activity.userId, // 目标用户 ID
                    showFollowButton: false, // 不显示关注按钮
                    showLevel: false, // 不显示等级
                  ),
                ],
              ),

              if (activity.content.isNotEmpty) ...[
                // 活动内容不为空时显示
                SizedBox(height: 8), // 间距
                Text(
                  activity.content, // 动态内容文本
                  maxLines: 2, // 最大行数
                  overflow: TextOverflow.ellipsis, // 溢出时显示省略号
                ),
              ],

              SizedBox(height: 8), // 间距
              Row(
                mainAxisSize: MainAxisSize.min, // 最小尺寸
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 内边距
                    decoration: BoxDecoration(
                      color: typeColor, // 背景颜色
                      borderRadius: BorderRadius.circular(12), // 圆角
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // 最小尺寸
                      children: [
                        Icon(Icons.favorite, size: 14), // 点赞图标
                        SizedBox(width: 4), // 间距
                        Text('${activity.likesCount}'), // 点赞计数
                      ],
                    ),
                  ),
                  SizedBox(width: 8), // 间距
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 内边距
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100, // 背景颜色
                      borderRadius: BorderRadius.circular(12), // 圆角
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // 最小尺寸
                      children: [
                        Icon(Icons.comment, size: 14), // 评论图标
                        SizedBox(width: 4), // 间距
                        Text('${activity.commentsCount}'), // 评论计数
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

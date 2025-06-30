// lib/models/activity/activity_target_navigation_route.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/activity.dart';
import 'package:suxingchahui/routes/app_routes.dart';

class ActivityTargetNavigationRoute {
  final String buttonText; // 按钮文本
  final IconData icon; // 按钮图标
  final String route; // 导航路由
  final dynamic arguments; // 路由参数

  const ActivityTargetNavigationRoute({
    required this.buttonText,
    required this.icon,
    required this.route,
    required this.arguments,
  });

  factory ActivityTargetNavigationRoute.fromActivity(Activity activity) =>
      getNavigationText(activity);

  static ActivityTargetNavigationRoute getNavigationText(Activity activity) {
    String buttonText; // 按钮文本
    IconData icon; // 按钮图标
    String route; // 导航路由
    dynamic arguments; // 路由参数
    // 根据动态目标类型设置按钮文本、图标和导航信息
    switch (activity.targetType) {
      case Activity.targetGame: // 目标类型为游戏
        buttonText = '查看游戏';
        icon = Icons.sports_esports;
        route = AppRoutes.gameDetail;
        arguments = activity.targetId;
        break;
      case Activity.targetPost: // 目标类型为帖子
        buttonText = '查看帖子';
        icon = Icons.forum;
        route = AppRoutes.postDetail;
        arguments = activity.targetId;
        break;
      case Activity.targetUser: // 目标类型为用户
        buttonText = '查看用户';
        icon = Icons.person;
        route = AppRoutes.openProfile;
        arguments = activity.targetId;
        break;
      default: // 未知类型
        buttonText = '查看详情';
        icon = Icons.arrow_forward;
        route = ''; // 空路由表示不导航
        arguments = null;
    }
    return ActivityTargetNavigationRoute(
        buttonText: buttonText, icon: icon, route: route, arguments: arguments);
  }
}

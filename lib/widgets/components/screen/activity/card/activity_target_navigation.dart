// lib/widgets/components/screen/activity/card/activity_target_navigation.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/activity/activity_constants.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class ActivityTargetNavigation extends StatelessWidget {
  final UserActivity activity;
  final bool isAlternate;

  const ActivityTargetNavigation({
    super.key,
    required this.activity,
    this.isAlternate = false,
  });

  @override
  Widget build(BuildContext context) {
    // 如果没有目标ID或类型，不显示导航按钮
    if (activity.targetId.isEmpty || activity.targetType.isEmpty) {
      return const SizedBox.shrink();
    }

    // 根据目标类型获取显示文本、图标和路由
    String buttonText;
    IconData icon;
    String route;
    dynamic arguments;

    switch (activity.targetType) {
      case ActivityTargetTypeConstants.game:
        buttonText = '查看游戏';
        icon = Icons.sports_esports;
        route = AppRoutes.gameDetail;
        arguments = activity.targetId;
        break;
      case ActivityTargetTypeConstants.post:
        buttonText = '查看帖子';
        icon = Icons.forum;
        route = AppRoutes.postDetail;
        arguments = activity.targetId;
        break;
      case ActivityTargetTypeConstants.user:
        buttonText = '查看用户';
        icon = Icons.person;
        route = AppRoutes.openProfile;
        arguments = activity.targetId;
        break;
      default:
      // 如果是未知类型，显示通用的消息
        buttonText = '查看详情';
        icon = Icons.arrow_forward;
        route = ''; // 空路由表示不导航
        arguments = null;
    }

    // 如果没有有效路由，不显示导航按钮
    if (route.isEmpty) {
      return const SizedBox.shrink();
    }

    // 创建导航按钮
    return Container(
      margin: const EdgeInsets.only(top: 12.0, bottom: 4.0),
      child: OutlinedButton.icon(
        onPressed: () {
          // 导航到目标页面
          NavigationUtils.of(context).pushNamed(
            route,
            arguments: arguments,
          );
        },
        icon: Icon(
          icon,
          size: 18,
          color: Theme.of(context).primaryColor,
        ),
        label: Text(
          buttonText,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).primaryColor.withSafeOpacity(0.5),
            width: 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          backgroundColor: Theme.of(context).primaryColor.withSafeOpacity(0.05),
        ),
      ),
    );
  }
}
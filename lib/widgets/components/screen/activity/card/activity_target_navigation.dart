// lib/widgets/components/screen/activity/card/activity_target_navigation.dart

/// 该文件定义了 ActivityTargetNavigation 组件，用于显示动态目标导航按钮。
/// ActivityTargetNavigation 根据动态的目标类型提供相应的查看详情功能。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/constants/activity/activity_constants.dart'; // 动态类型常量
import 'package:suxingchahui/models/activity/user_activity.dart'; // 用户动态模型
import 'package:suxingchahui/routes/app_routes.dart'; // 应用路由
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法

/// `ActivityTargetNavigation` 类：动态目标导航组件。
///
/// 该组件根据动态的目标类型（游戏、帖子、用户）渲染一个导航按钮，
/// 点击后跳转到对应目标的详情页面。
class ActivityTargetNavigation extends StatelessWidget {
  final UserActivity activity; // 动态数据
  final bool isAlternate; // 是否使用交替布局样式

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [activity]：要导航的动态数据。
  /// [isAlternate]：是否使用交替布局样式。
  const ActivityTargetNavigation({
    super.key,
    required this.activity,
    this.isAlternate = false,
  });

  /// 构建 Widget。
  ///
  /// 根据动态目标类型和 ID 构建导航按钮。
  @override
  Widget build(BuildContext context) {
    if (activity.targetId.isEmpty || activity.targetType.isEmpty) {
      // 如果没有目标 ID 或类型，不显示导航按钮
      return const SizedBox.shrink(); // 返回空 Widget
    }

    String buttonText; // 按钮文本
    IconData icon; // 按钮图标
    String route; // 导航路由
    dynamic arguments; // 路由参数

    // 根据动态目标类型设置按钮文本、图标和导航信息
    switch (activity.targetType) {
      case ActivityTargetTypeConstants.game: // 目标类型为游戏
        buttonText = '查看游戏';
        icon = Icons.sports_esports;
        route = AppRoutes.gameDetail;
        arguments = activity.targetId;
        break;
      case ActivityTargetTypeConstants.post: // 目标类型为帖子
        buttonText = '查看帖子';
        icon = Icons.forum;
        route = AppRoutes.postDetail;
        arguments = activity.targetId;
        break;
      case ActivityTargetTypeConstants.user: // 目标类型为用户
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

    if (route.isEmpty) {
      // 如果没有有效路由，不显示导航按钮
      return const SizedBox.shrink(); // 返回空 Widget
    }

    // 创建导航按钮
    return Container(
      margin: const EdgeInsets.only(top: 12.0, bottom: 4.0), // 外边距
      child: OutlinedButton.icon(
        onPressed: () {
          // 按钮点击回调
          NavigationUtils.of(context).pushNamed(
            // 导航到目标页面
            route,
            arguments: arguments,
          );
        },
        icon: Icon(
          icon, // 按钮图标
          size: 18,
          color: Theme.of(context).primaryColor, // 图标颜色
        ),
        label: Text(
          buttonText, // 按钮文本
          style: TextStyle(
            color: Theme.of(context).primaryColor, // 文本颜色
            fontWeight: FontWeight.w500, // 字体粗细
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).primaryColor.withSafeOpacity(0.5), // 边框颜色
            width: 1.0, // 边框宽度
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0), // 边框圆角
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 8.0), // 内边距
          backgroundColor:
              Theme.of(context).primaryColor.withSafeOpacity(0.05), // 背景颜色
        ),
      ),
    );
  }
}

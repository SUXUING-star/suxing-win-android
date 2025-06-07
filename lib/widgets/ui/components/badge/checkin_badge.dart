// lib/widgets/ui/components/badge/checkin_badge.dart

/// 该文件定义了 CheckInBadge 组件，一个显示用户签到状态的徽章。
/// CheckInBadge 根据用户的今日签到状态显示不同颜色，并支持点击跳转到签到页面。
library;

import 'package:flutter/material.dart'; // Flutter UI 框架
import 'package:suxingchahui/routes/app_routes.dart'; // 应用路由常量
import 'package:suxingchahui/services/main/user/user_checkin_service.dart'; // 用户签到服务
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类

/// `CheckInBadge` 类：用户签到状态徽章。
///
/// 该组件通过 `StreamBuilder` 监听用户签到服务，
/// 根据用户的今日签到状态显示不同的颜色，并支持点击跳转到签到页面。
class CheckInBadge extends StatelessWidget {
  final UserCheckInService checkInService; // 用户签到服务实例

  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  /// [checkInService]：用户签到服务实例。
  const CheckInBadge({
    super.key,
    required this.checkInService,
  });

  /// 构建签到徽章 UI。
  ///
  /// [context]：Build 上下文。
  /// 返回一个根据签到状态变化的 `GestureDetector` 组件。
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      // 监听签到服务的 Stream
      stream: checkInService.checkedTodayStream, // 监听今日是否已签到状态
      initialData: checkInService.checkedTodayNotifier.value, // 初始数据
      builder: (context, snapshot) {
        // 构建器函数
        final bool hasCheckedToday = snapshot.data ?? false; // 获取今日是否已签到状态

        return GestureDetector(
          // 可点击手势检测器
          onTap: () {
            // 点击事件回调
            NavigationUtils.pushNamed(
              // 导航到签到页面
              context,
              AppRoutes.checkin,
            );
          },
          child: Container(
            // 徽章容器
            width: 24, // 宽度
            height: 24, // 高度
            decoration: BoxDecoration(
              // 装饰
              color: hasCheckedToday
                  ? Colors.blue[400]
                  : Colors.green, // 根据签到状态设置颜色
              shape: BoxShape.circle, // 圆形
            ),
            child: Center(
              // 内容居中
              child: Icon(
                // 图标
                Icons.calendar_today, // 日历图标
                size: 16, // 图标大小
                color: Colors.white, // 图标颜色
              ),
            ),
          ),
        );
      },
    );
  }
}

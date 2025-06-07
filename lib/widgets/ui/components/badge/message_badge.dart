// lib/widgets/ui/components/badge/message_badge.dart

/// 该文件定义了 MessageBadge 组件，一个显示未读消息数量的徽章。
/// MessageBadge 监听未读消息流，并根据数量显示不同的 UI 样式，支持点击跳转到消息页面。
library;

import 'package:flutter/material.dart'; // Flutter UI 框架
import 'package:suxingchahui/routes/app_routes.dart'; // 应用路由常量
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类
import 'package:suxingchahui/services/main/message/message_service.dart'; // 消息服务

/// `MessageBadge` 类：未读消息数量徽章。
///
/// 该组件通过 `StreamBuilder` 监听消息服务的未读消息流，
/// 根据未读消息数量显示不同的徽章样式，并支持点击跳转到消息页面。
class MessageBadge extends StatelessWidget {
  final MessageService messageService; // 消息服务实例

  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  /// [messageService]：消息服务实例。
  const MessageBadge({
    super.key,
    required this.messageService,
  });

  /// 构建消息徽章 UI。
  ///
  /// [context]：Build 上下文。
  /// 返回一个根据未读消息数量变化的 `GestureDetector` 组件。
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      // 监听消息服务的未读消息流
      stream: messageService.getUnreadCountStream(), // 监听未读消息数量
      builder: (context, snapshot) {
        // 构建器函数
        final unreadCount = snapshot.data ?? 0; // 获取未读消息数量，默认为 0

        return GestureDetector(
          // 可点击手势检测器
          onTap: () {
            // 点击事件回调
            NavigationUtils.pushNamed(context, AppRoutes.message); // 导航到消息页面
          },
          child: unreadCount > 0 // 根据未读消息数量判断显示样式
              ? Container(
                  // 有未读消息时的容器样式
                  width: 24, // 宽度
                  height: 24, // 高度
                  decoration: BoxDecoration(
                    // 装饰
                    color: Colors.blue, // 蓝色背景
                    shape: BoxShape.circle, // 圆形
                  ),
                  child: Center(
                    // 内容居中
                    child: Text(
                      // 文本显示未读数量
                      unreadCount > 99
                          ? '99+'
                          : unreadCount.toString(), // 超过 99 显示 99+
                      style: TextStyle(
                        // 文本样式
                        color: Colors.white, // 白色文字
                        fontSize: 10, // 字体大小
                        fontWeight: FontWeight.bold, // 粗体
                      ),
                      textAlign: TextAlign.center, // 文本居中
                    ),
                  ),
                )
              : Container(
                  // 无未读消息时的容器样式
                  width: 24, // 宽度
                  height: 24, // 高度
                  decoration: BoxDecoration(
                    // 装饰
                    color: Colors.blue[300], // 浅蓝色背景
                    shape: BoxShape.circle, // 圆形
                  ),
                  child: Center(
                    // 内容居中
                    child: Icon(
                      // 图标显示通知
                      Icons.notifications_none_rounded, // 通知图标
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

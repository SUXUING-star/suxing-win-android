// lib/wrapper/platform_wrapper.dart

/// 该文件定义了 PlatformWrapper 组件，一个用于根据平台类型适配布局的包装器。
/// PlatformWrapper 为桌面平台提供自定义框架布局，为其他平台直接返回子组件。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/layouts/desktop/desktop_frame_layout.dart'; // 导入桌面框架布局
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart'; // 导入侧边栏 Provider
import 'package:suxingchahui/services/main/announcement/announcement_service.dart'; // 导入公告服务
import 'package:suxingchahui/services/main/message/message_service.dart'; // 导入消息服务
import 'package:suxingchahui/services/main/user/user_checkin_service.dart'; // 导入用户签到服务
import 'package:suxingchahui/utils/device/device_utils.dart'; // 导入设备工具类

/// `PlatformWrapper` 类：根据平台类型适配布局的包装器组件。
///
/// 该组件根据当前设备是否为桌面平台，选择性地使用 DesktopFrameLayout 包裹子组件，
/// 以赋予桌面端持久化侧边栏和窗口控制功能。
class PlatformWrapper extends StatelessWidget {
  final Widget child; // 被包装的子组件
  final SidebarProvider sidebarProvider; // 侧边栏 Provider
  final AuthProvider authProvider; // 认证 Provider
  final MessageService messageService; // 消息服务
  final AnnouncementService announcementService; // 公告服务
  final UserCheckInService checkInService; // 用户签到服务

  /// 构造函数。
  ///
  /// [child]：子组件。
  /// [sidebarProvider]：侧边栏 Provider。
  /// [authProvider]：认证 Provider。
  /// [messageService]：消息服务。
  /// [checkInService]：签到服务。
  /// [announcementService]：公告服务。
  const PlatformWrapper({
    super.key,
    required this.child,
    required this.sidebarProvider,
    required this.authProvider,
    required this.messageService,
    required this.checkInService,
    required this.announcementService,
  });

  /// 构建平台包装器组件。
  ///
  /// 该方法根据 [DeviceUtils.isDesktop] 判断当前平台类型，
  /// 如果是桌面平台，则使用 [DesktopFrameLayout] 包裹 [child]；
  /// 否则，直接返回 [child]。
  @override
  Widget build(BuildContext context) {
    if (DeviceUtils.isDesktop) {
      // 如果是桌面平台
      return DesktopFrameLayout(
        checkInService: checkInService, // 签到服务
        announcementService: announcementService, // 公告服务
        sidebarProvider: sidebarProvider, // 侧边栏 Provider
        authProvider: authProvider, // 认证 Provider
        messageService: messageService, // 消息服务
        showSidebar: true, // 显示侧边栏
        showTitleBarActions: true, // 显示标题栏动作按钮
        child: child, // 被包装的子组件
      );
    } else {
      // 非桌面平台
      return child; // 直接返回子组件
    }
  }
}

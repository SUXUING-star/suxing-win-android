// lib/wrapper/platform_wrapper.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/layouts/desktop/desktop_frame_layout.dart.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/services/main/announcement/announcement_service.dart';
import 'package:suxingchahui/services/main/message/message_service.dart';
import 'package:suxingchahui/services/main/user/user_checkin_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';

class PlatformWrapper extends StatelessWidget {
  final Widget child;
  final SidebarProvider sidebarProvider;
  final AuthProvider authProvider;
  final MessageService messageService;
  final AnnouncementService announcementService;
  final UserCheckInService checkInService;

  const PlatformWrapper({
    super.key,
    required this.child,
    required this.sidebarProvider,
    required this.authProvider,
    required this.messageService,
    required this.checkInService,
    required this.announcementService,
  });
  @override
  Widget build(BuildContext context) {
    if (DeviceUtils.isDesktop) {
      return DesktopFrameLayout(
        checkInService: checkInService,
        announcementService: announcementService,
        sidebarProvider: sidebarProvider,
        authProvider: authProvider,
        messageService: messageService,
        showSidebar: true, // 正常模式下显示侧边栏
        showTitleBarActions: true,
        child: child, // 正常模式下显示动作按钮
      );
    } else {
      // 非桌面平台，直接返回原始的 child
      return child;
    }
  }
}
// Modify platform_wrapper.dart

import 'package:flutter/material.dart';
import '../utils/device/device_utils.dart';
import '../layouts/desktop/desktop_sidebar.dart';
import 'package:provider/provider.dart';
import '../providers/navigation/sidebar_provider.dart';  // Make sure this provider exists

class PlatformWrapper extends StatelessWidget {
  final Widget child;

  const PlatformWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 在桌面平台上应用侧边栏
    if (DeviceUtils.isDesktop) {
      // Use the SidebarProvider to get the current selected index
      return Consumer<SidebarProvider>(
        builder: (context, sidebarProvider, _) {
          return DesktopSidebar(
              currentIndex: sidebarProvider.currentIndex,
              child: child
          );
        },
      );
    }

    // 在移动平台上直接返回原内容
    return child;
  }
}
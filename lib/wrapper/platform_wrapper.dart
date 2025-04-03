// lib/wrapper/platform_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 引入 Provider
import '../utils/device/device_utils.dart';
import '../layouts/desktop/desktop_sidebar.dart'; // 引入 DesktopSidebar
import '../providers/navigation/sidebar_provider.dart'; // *** 引入 SidebarProvider ***

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
      // *** 使用 Consumer 或 context.watch 来获取 SidebarProvider 的状态 ***
      return Consumer<SidebarProvider>( // 或者使用 context.watch
        builder: (context, sidebarProvider, _) {
          print("PlatformWrapper build (Desktop): currentIndex=${sidebarProvider.currentIndex}"); // 添加日志
          // *** 将从 Provider 获取的 currentIndex 传递给 DesktopSidebar ***
          return DesktopSidebar(
            currentIndex: sidebarProvider.currentIndex,
            child: child,
          );
        },
      );
    }

    // 在移动平台上直接返回原内容
    print("PlatformWrapper build (Mobile)"); // 添加日志
    return child;
  }
}
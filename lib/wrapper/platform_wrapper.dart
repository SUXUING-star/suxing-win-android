// lib/wrapper/platform_wrapper.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/layouts/desktop/desktop_frame_layout.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';

class PlatformWrapper extends StatelessWidget {
  final Widget child;

  const PlatformWrapper({
    super.key,
    required this.child,
  });

  // 标题栏高度常量可以移到 DesktopFrameLayout 或保留在这里供外部引用
  static const double kDesktopTitleBarHeight = 35.0;

  @override
  Widget build(BuildContext context) {
    if (DeviceUtils.isDesktop) {
      // *** 直接返回 DesktopFrameLayout ***
      return DesktopFrameLayout(
        showSidebar: true, // 正常模式下显示侧边栏
        showTitleBarActions: true,
        child: child, // 正常模式下显示动作按钮
        // 可以按需传递 titleBarGradient, titleText, titleIconPath
      );
    } else {
      // 非桌面平台，直接返回原始的 child
      return child;
    }
  }
// _buildTitleBarButtonWrapper 方法可以移到 DesktopFrameLayout 或删除
}
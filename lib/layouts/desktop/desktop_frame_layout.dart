// lib/widgets/layouts/desktop/desktop_frame_layout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/widgets/components/badge/layout/checkin_badge.dart';
import 'package:suxingchahui/widgets/components/badge/layout/message_badge.dart';
import 'package:suxingchahui/widgets/components/badge/layout/update_button.dart';
import 'package:suxingchahui/widgets/components/indicators/announcement_indicator.dart';
import 'desktop_sidebar.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart';
import 'package:suxingchahui/windows/ui/windows_controls.dart';
import 'package:suxingchahui/wrapper/platform_wrapper.dart'; // For kDesktopTitleBarHeight
import 'package:window_manager/window_manager.dart';

class DesktopFrameLayout extends StatelessWidget {
  /// 要显示的主要内容 Widget
  final Widget child;

  /// 是否显示侧边栏 (默认为 true)
  final bool showSidebar;

  /// 是否显示标题栏上的动作按钮 (消息、签到等，默认为 true)
  final bool showTitleBarActions;

  /// 可选的标题栏渐变背景，不提供则使用默认
  final Gradient? titleBarGradient;

  /// 可选的标题文字，不提供则使用默认
  final String? titleText;

  /// 可选的标题图标路径，不提供则使用默认
  final String? titleIconPath;

  const DesktopFrameLayout({
    super.key,
    required this.child,
    this.showSidebar = true, // 默认显示侧边栏
    this.showTitleBarActions = true, // 默认显示动作按钮
    this.titleBarGradient,
    this.titleText,
    this.titleIconPath,
  });

  static const List<Color> desktopBarColor = [
    Color(0x000000ff),
    Color(0xFFD8FFEF),
    Color(0x000000ff),
  ];

  // 默认标题栏渐变
  static final Gradient _defaultTitleBarGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      ...desktopBarColor
    ],
  );

  // 默认标题和图标
  static const String _defaultTitleText = '宿星茶会(windows)';
  static const String _defaultTitleIconPath =
      'assets/images/icons/app_icon.jpg';

  @override
  Widget build(BuildContext context) {
    // 1. 给主内容区域加上顶部的 Padding
    Widget paddedChild = Padding(
      padding:
          const EdgeInsets.only(top: PlatformWrapper.kDesktopTitleBarHeight),
      child: child,
    );

    // 2. 根据 showSidebar 构建基础布局
    Widget baseLayout = showSidebar
        ? DesktopSidebar(child: paddedChild) // 如果显示侧边栏，用 DesktopSidebar 包裹
        : paddedChild; // 否则直接使用带 Padding 的 child

    // 3. 使用 Stack 将自定义标题栏叠加在基础布局之上
    return Stack(
      children: [
        // --- 底层：基础布局 (可能含侧边栏) ---
        Positioned.fill(child: baseLayout),

        // --- 顶层：自定义标题栏 ---
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: PlatformWrapper.kDesktopTitleBarHeight,
          child: Material(
            elevation: 1.0, // 可选阴影
            child: Row(
              children: [
                // --- a) 可拖拽区域 (含图标和标题) ---
                Expanded(
                  child: DragToMoveArea(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: titleBarGradient ??
                            _defaultTitleBarGradient, // 使用传入或默认渐变
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  titleIconPath ??
                                      _defaultTitleIconPath, // 使用传入或默认图标
                                  height: 24.0,
                                  width: 24.0,
                                  filterQuality: FilterQuality.medium,
                                ),
                                const SizedBox(width: 8.0),
                                AppText(
                                  titleText ?? _defaultTitleText, // 使用传入或默认标题
                                  color: Colors.black,
                                  fontSize: 13,
                                  maxLines: 1,
                                  type: AppTextType.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // 中间空白填充，确保可拖拽
                          Expanded(
                            child: Container(color: Colors.transparent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- b) 动作按钮区域 (条件显示) ---
                if (showTitleBarActions) // *** 根据参数决定是否显示 ***
                  Consumer<AuthProvider>(
                    // 仍然需要 Consumer 来判断登录状态
                    builder: (context, authProvider, _) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTitleBarButtonWrapper(UpdateButton(), '检查更新'),
                          _buildTitleBarButtonWrapper(
                              AnnouncementIndicator(), '查看公告'),
                          if (authProvider.isLoggedIn)
                            _buildTitleBarButtonWrapper(MessageBadge(), '未读消息'),
                          _buildTitleBarButtonWrapper(CheckInBadge(), '每日签到'),
                          const SizedBox(width: 8), // 与窗口控件的间距
                        ],
                      );
                    },
                  )
                else // 如果不显示动作按钮，仍然加一点间距，避免窗口控件紧贴拖拽区
                  const SizedBox(width: 8),

                // --- c) 标准窗口控制按钮 (始终显示) ---
                WindowsControls(
                  iconColor: Colors.black.withOpacity(0.9),
                  hoverColor: Colors.blue.withOpacity(0.1),
                  closeHoverColor: Colors.red.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 辅助方法：构建标题栏按钮 (保持不变) ---
  Widget _buildTitleBarButtonWrapper(
      Widget buttonChild, String tooltipMessage) {
    return Tooltip(
      message: tooltipMessage,
      waitDuration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      preferBelow: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          height: PlatformWrapper.kDesktopTitleBarHeight,
          width: 40,
          child: Center(child: buttonChild),
        ),
      ),
    );
  }
}

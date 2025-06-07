// lib/layouts/desktop/desktop_frame_layout.dart

/// 该文件定义了 DesktopFrameLayout 组件，用于构建桌面应用的整体框架布局。
/// DesktopFrameLayout 包含自定义标题栏、侧边栏和主要内容区域。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/constants/global_constants.dart'; // 导入全局常量
import 'package:suxingchahui/layouts/desktop/desktop_sidebar.dart'; // 导入桌面侧边栏布局
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart'; // 导入侧边栏 Provider
import 'package:suxingchahui/services/main/announcement/announcement_service.dart'; // 导入公告服务
import 'package:suxingchahui/services/main/message/message_service.dart'; // 导入消息服务
import 'package:suxingchahui/services/main/user/user_checkin_service.dart'; // 导入用户签到服务
import 'package:suxingchahui/widgets/ui/components/badge/checkin_badge.dart'; // 导入签到徽章
import 'package:suxingchahui/widgets/ui/components/badge/message_badge.dart'; // 导入消息徽章
import 'package:suxingchahui/widgets/ui/components/badge/update_button.dart'; // 导入更新按钮
import 'package:suxingchahui/widgets/ui/components/badge/announcement_indicator.dart'; // 导入公告指示器
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart'; // 导入应用文本类型
import 'package:suxingchahui/windows/ui/windows_controls.dart'; // 导入 Windows 窗口控制按钮
import 'package:window_manager/window_manager.dart'; // 导入窗口管理器库

/// `DesktopFrameLayout` 类：桌面应用框架布局组件。
///
/// 该组件提供桌面应用窗口的整体布局，包括自定义标题栏、侧边栏和主要内容区域。
class DesktopFrameLayout extends StatelessWidget {
  final SidebarProvider sidebarProvider; // 侧边栏 Provider 实例
  final AuthProvider authProvider; // 认证 Provider 实例
  final MessageService messageService; // 消息服务实例
  final UserCheckInService checkInService; // 用户签到服务实例
  final AnnouncementService announcementService; // 公告服务实例
  final Widget child; // 主要内容区域组件
  final bool showSidebar; // 是否显示侧边栏
  final bool showTitleBarActions; // 是否显示标题栏上的动作按钮
  final Gradient? titleBarGradient; // 标题栏渐变背景
  final String? titleText; // 标题栏文本
  final String? titleIconPath; // 标题栏图标路径

  /// 构造函数。
  ///
  /// [announcementService]：公告服务。
  /// [authProvider]：认证 Provider。
  /// [sidebarProvider]：侧边栏 Provider。
  /// [messageService]：消息服务。
  /// [checkInService]：签到服务。
  /// [child]：主要内容。
  /// [showSidebar]：是否显示侧边栏。
  /// [showTitleBarActions]：是否显示标题栏动作按钮。
  /// [titleBarGradient]：标题栏渐变。
  /// [titleText]：标题文本。
  /// [titleIconPath]：标题图标路径。
  const DesktopFrameLayout({
    super.key,
    required this.announcementService,
    required this.authProvider,
    required this.sidebarProvider,
    required this.messageService,
    required this.checkInService,
    required this.child,
    this.showSidebar = true,
    this.showTitleBarActions = true,
    this.titleBarGradient,
    this.titleText,
    this.titleIconPath,
  });

  static const List<Color> desktopBarColor = [
    Color(0x000000ff), // 桌面栏颜色列表，用于渐变
    Color(0xFFD8FFEF),
    Color(0x000000ff),
  ];

  static const double kDesktopTitleBarHeight = 35.0; // 桌面标题栏高度

  static final Gradient _defaultTitleBarGradient = LinearGradient(
    begin: Alignment.centerLeft, // 默认标题栏渐变起始点
    end: Alignment.centerRight, // 默认标题栏渐变结束点
    colors: [...desktopBarColor], // 默认标题栏渐变颜色
  );

  static const String _defaultTitleText =
      GlobalConstants.appNameWindows; // 默认标题文本
  static const String _defaultTitleIconPath =
      GlobalConstants.appIcon; // 默认标题图标路径

  /// 构建桌面框架布局。
  ///
  /// 该方法通过堆叠布局组合标题栏、侧边栏和主要内容。
  @override
  Widget build(BuildContext context) {
    // 1. 主要内容区域添加顶部填充
    Widget paddedChild = Padding(
      padding: const EdgeInsets.only(top: kDesktopTitleBarHeight), // 顶部填充标题栏高度
      child: child, // 主要内容
    );

    // 2. 根据 showSidebar 参数构建基础布局
    Widget baseLayout = showSidebar
        ? DesktopSidebar(
            sidebarProvider: sidebarProvider,
            authProvider: authProvider,
            child: paddedChild,
          ) // 显示侧边栏时使用 DesktopSidebar 包裹
        : paddedChild; // 不显示侧边栏时直接使用带填充的子组件

    // 应用程序标题和图标组件
    Widget appTitleIconWidget = DragToMoveArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: titleBarGradient ?? _defaultTitleBarGradient, // 使用传入或默认渐变
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    titleIconPath ?? _defaultTitleIconPath, // 使用传入或默认图标
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
            // 中间空白填充，确保可拖拽区域
            Expanded(
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
      ),
    );

    // 应用程序工具栏组件
    Widget appToolBarWidget = StreamBuilder<bool>(
      stream: authProvider.isLoggedInStream, // 监听登录状态流
      initialData: authProvider.isLoggedIn, // 初始登录状态
      builder: (context, isLoggedInSnapshot) {
        final bool isLoggedIn =
            isLoggedInSnapshot.data ?? authProvider.isLoggedIn; // 获取登录状态
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitleBarButtonWrapper(const UpdateButton(), '检查更新'), // 更新按钮
            _buildTitleBarButtonWrapper(
                AnnouncementIndicator(
                  authProvider: authProvider,
                  announcementService: announcementService,
                ),
                '查看公告'), // 公告指示器
            if (isLoggedIn) // 登录时显示消息徽章
              _buildTitleBarButtonWrapper(
                  MessageBadge(
                    messageService: messageService,
                  ),
                  '未读消息'),
            _buildTitleBarButtonWrapper(
                CheckInBadge(
                  checkInService: checkInService,
                ),
                '每日签到'), // 签到徽章
            const SizedBox(width: 8),
          ],
        );
      },
    );

    // 3. 使用 Stack 将自定义标题栏叠加在基础布局之上
    return Stack(
      children: [
        Positioned.fill(child: baseLayout), // 基础布局填充整个空间
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: kDesktopTitleBarHeight, // 标题栏高度
          child: Material(
            elevation: 1.0, // 标题栏阴影
            child: Row(
              children: [
                Expanded(
                  child: appTitleIconWidget, // 标题和图标区域
                ),

                if (showTitleBarActions) // 条件显示动作按钮区域
                  appToolBarWidget
                else
                  const SizedBox(width: 8), // 不显示动作按钮时添加间距

                WindowsControls(
                  // 标准窗口控制按钮
                  iconColor: Colors.black.withSafeOpacity(0.9),
                  hoverColor: Colors.blue.withSafeOpacity(0.1),
                  closeHoverColor: Colors.red.withSafeOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建标题栏按钮的包装组件。
  ///
  /// [buttonChild]：按钮的子组件。
  /// [tooltipMessage]：按钮的工具提示消息。
  /// 返回一个包含工具提示和鼠标区域的包装组件。
  Widget _buildTitleBarButtonWrapper(
      Widget buttonChild, String tooltipMessage) {
    return Tooltip(
      message: tooltipMessage, // 提示消息
      waitDuration: const Duration(milliseconds: 500), // 等待时长
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 提示内边距
      decoration: BoxDecoration(
        color: Colors.black.withSafeOpacity(0.8), // 提示背景色
        borderRadius: BorderRadius.circular(4), // 提示圆角
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12), // 提示文本样式
      preferBelow: true, // 提示优先显示在下方
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // 鼠标悬停显示点击光标
        child: SizedBox(
          height: kDesktopTitleBarHeight, // 高度
          width: 40, // 宽度
          child: Center(child: buttonChild), // 按钮内容居中
        ),
      ),
    );
  }
}

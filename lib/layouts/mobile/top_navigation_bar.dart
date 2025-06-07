// lib/layouts/mobile/top_navigation_bar.dart

/// 该文件定义了 TopNavigationBar 组件，一个自定义的移动端顶部导航栏。
/// TopNavigationBar 包含搜索栏、动作按钮和用户头像。
library;

import 'dart:ui' as ui; // 导入 dart:ui，用于获取屏幕物理尺寸
import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/routes/app_routes.dart'; // 导入应用路由
import 'package:suxingchahui/services/main/announcement/announcement_service.dart'; // 导入公告服务
import 'package:suxingchahui/services/main/message/message_service.dart'; // 导入消息服务
import 'package:suxingchahui/services/main/user/user_checkin_service.dart'; // 导入用户签到服务
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/utils/device/device_utils.dart'; // 导入设备工具类
import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/widgets/ui/components/badge/update_button.dart'; // 导入更新按钮
import 'package:suxingchahui/widgets/ui/components/badge/message_badge.dart'; // 导入消息徽章
import 'package:suxingchahui/widgets/ui/components/badge/announcement_indicator.dart'; // 导入公告指示器
import 'package:suxingchahui/widgets/ui/components/badge/checkin_badge.dart'; // 导入签到徽章
import 'package:suxingchahui/widgets/ui/badges/safe_user_avatar.dart'; // 导入安全用户头像组件

/// `TopNavigationBar` 类：自定义移动端顶部导航栏组件。
///
/// 该组件提供搜索栏、更新按钮、公告指示器、消息徽章、签到徽章和用户头像。
class TopNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogoTap; // Logo 点击回调
  final VoidCallback onProfileTap; // 个人资料点击回调
  final AuthProvider authProvider; // 认证 Provider
  final MessageService messageService; // 消息服务
  final AnnouncementService announcementService; // 公告服务
  final UserCheckInService checkInService; // 用户签到服务

  /// 构造函数。
  ///
  /// [authProvider]：认证 Provider。
  /// [onLogoTap]：Logo 点击回调。
  /// [onProfileTap]：个人资料点击回调。
  /// [messageService]：消息服务。
  /// [announcementService]：公告服务。
  /// [checkInService]：签到服务。
  const TopNavigationBar({
    super.key,
    required this.authProvider,
    required this.onLogoTap,
    required this.onProfileTap,
    required this.messageService,
    required this.announcementService,
    required this.checkInService,
  });

  /// 返回顶部导航栏的首选尺寸。
  ///
  /// 根据设备是否为 Android 横屏模式调整高度。
  @override
  Size get preferredSize {
    final ui.FlutterView? view =
        ui.PlatformDispatcher.instance.implicitView; // 获取主视图信息
    if (view != null) {
      final bool isLandscape =
          view.physicalSize.width > view.physicalSize.height; // 判断是否为横屏
      if (DeviceUtils.isAndroid && isLandscape) {
        // Android 横屏时
        return Size.fromHeight(kToolbarHeight * 0.8); // 返回调整后的高度
      }
    }
    return Size.fromHeight(kToolbarHeight); // 默认高度
  }

  /// 构建顶部导航栏。
  @override
  Widget build(BuildContext context) {
    final bool isActualAndroidLandscape = DeviceUtils.isAndroid &&
        (MediaQuery.of(context).orientation ==
            Orientation.landscape); // 判断是否为实际的 Android 横屏

    final double verticalPadding =
        isActualAndroidLandscape ? 4.0 : 8.0; // 垂直内边距
    final double iconSize = isActualAndroidLandscape ? 18.0 : 20.0; // 图标大小
    final double searchBarHeight =
        isActualAndroidLandscape ? 32.0 : 40.0; // 搜索栏高度
    final double avatarRadius = isActualAndroidLandscape ? 12.0 : 14.0; // 头像半径

    return AppBar(
      elevation: 0, // 阴影高度
      backgroundColor: Colors.white, // 背景色
      iconTheme: IconThemeData(color: Colors.grey[700]), // 图标主题
      title: _buildSearchBar(context, searchBarHeight, iconSize), // 搜索栏
      titleSpacing: 8.0, // 标题间距
      actions: [
        // 动作按钮列表
        MouseRegion(
          cursor: SystemMouseCursors.click, // 鼠标悬停显示点击光标
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding), // 垂直内边距
            child: const UpdateButton(), // 更新按钮
          ),
        ),
        const SizedBox(width: 8), // 间距
        _buildAnnouncementIndicator(context, verticalPadding), // 公告指示器
        const SizedBox(width: 8), // 间距
        _buildMessageBadge(context, verticalPadding), // 消息徽章
        const SizedBox(width: 8), // 间距
        _buildCheckInBadge(context, verticalPadding), // 签到徽章
        const SizedBox(width: 8), // 间距
        _buildProfileAvatar(context, avatarRadius, verticalPadding), // 用户头像
        const SizedBox(width: 16), // 间距
      ],
    );
  }

  /// 构建签到徽章。
  ///
  /// [context]：Build 上下文。
  /// [padding]：内边距。
  /// 仅在用户登录时显示。
  Widget _buildCheckInBadge(BuildContext context, double padding) {
    if (authProvider.isLoggedIn) {
      // 用户登录时
      return MouseRegion(
        cursor: SystemMouseCursors.click, // 鼠标悬停显示点击光标
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: padding), // 垂直内边距
          child: CheckInBadge(
            checkInService: checkInService, // 签到服务
          ),
        ),
      );
    }
    return const SizedBox.shrink(); // 未登录时隐藏
  }

  /// 构建公告指示器。
  ///
  /// [context]：Build 上下文。
  /// [padding]：内边距。
  Widget _buildAnnouncementIndicator(BuildContext context, double padding) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // 鼠标悬停显示点击光标
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: padding), // 垂直内边距
        child: AnnouncementIndicator(
          authProvider: authProvider, // 认证 Provider
          announcementService: announcementService, // 公告服务
        ),
      ),
    );
  }

  /// 构建搜索栏。
  ///
  /// [context]：Build 上下文。
  /// [height]：搜索栏高度。
  /// [iconSize]：图标大小。
  Widget _buildSearchBar(BuildContext context, double height, double iconSize) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // 鼠标悬停显示点击光标
      child: Material(
        color: Colors.transparent, // 背景透明
        child: InkWell(
          onTap: () => NavigationUtils.pushNamed(
              context, AppRoutes.searchGame), // 点击导航到搜索游戏页面
          borderRadius: BorderRadius.circular(20), // 圆角
          child: Container(
            height: height, // 高度
            decoration: BoxDecoration(
              color: Colors.grey[100], // 背景色
              borderRadius: BorderRadius.circular(20), // 圆角
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12), // 水平内边距
                  child: Icon(Icons.search_rounded,
                      color: Colors.grey[400], size: iconSize), // 搜索图标
                ),
                Expanded(
                  child: Text(
                    '搜索游戏...', // 提示文本
                    style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: iconSize * 0.7), // 文本样式
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建消息徽章。
  ///
  /// [context]：Build 上下文。
  /// [padding]：内边距。
  /// 仅在用户登录时显示。
  Widget _buildMessageBadge(BuildContext context, double padding) {
    if (authProvider.isLoggedIn) {
      // 用户登录时
      return MouseRegion(
        cursor: SystemMouseCursors.click, // 鼠标悬停显示点击光标
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: padding), // 垂直内边距
          child: MessageBadge(messageService: messageService), // 消息徽章
        ),
      );
    }
    return const SizedBox.shrink(); // 未登录时隐藏
  }

  /// 构建用户头像。
  ///
  /// [context]：Build 上下文。
  /// [imageContentRadius]：头像图片内容半径。
  /// [appBarActionVerticalPadding]：顶部栏动作垂直内边距。
  Widget _buildProfileAvatar(BuildContext context, double imageContentRadius,
      double appBarActionVerticalPadding) {
    final Color avatarBorderColor = const Color(0xFF2979FF); // 头像边框颜色
    final double avatarBorderWidth = 1.5; // 头像边框宽度
    final Color avatarPlaceholderBackgroundColor =
        Colors.grey[100]!; // 头像占位符背景色

    final double suaRadius =
        imageContentRadius + avatarBorderWidth; // 安全用户头像的半径

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: appBarActionVerticalPadding, horizontal: 0), // 垂直内边距
      child: StreamBuilder<User?>(
        stream: authProvider.currentUserStream, // 监听当前用户流
        initialData: authProvider.currentUser, // 初始当前用户数据
        builder: (context, currentUserSnapshot) {
          final User? currentUser = currentUserSnapshot.data; // 获取当前用户数据

          if (currentUser == null) {
            // 用户未登录或信息未加载完成
            return SafeUserAvatar(
              key: const ValueKey('avatar_loading_user'), // 唯一键
              radius: suaRadius, // 半径
              onTap: onProfileTap, // 点击回调
              enableNavigation: false, // 禁用导航
              borderColor: avatarBorderColor, // 边框颜色
              borderWidth: avatarBorderWidth, // 边框宽度
              backgroundColor: avatarPlaceholderBackgroundColor, // 背景色
              placeholder: Icon(
                // 占位符图标
                Icons.person_outline_rounded,
                size: imageContentRadius * 1.3,
                color: Colors.grey[400],
              ),
            );
          }

          return SafeUserAvatar(
            key: ValueKey('avatar_user_${currentUser.id}'), // 唯一键
            userId: currentUser.id, // 用户ID
            avatarUrl: currentUser.avatar, // 头像 URL
            username: currentUser.username, // 用户名
            radius: suaRadius, // 半径
            onTap: onProfileTap, // 点击回调
            enableNavigation: false, // 禁用导航
            borderColor: avatarBorderColor, // 边框颜色
            borderWidth: avatarBorderWidth, // 边框宽度
            backgroundColor: avatarPlaceholderBackgroundColor, // 背景色
          );
        },
      ),
    );
  }
}

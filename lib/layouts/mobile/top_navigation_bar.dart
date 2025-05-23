// lib/layouts/mobile/top_navigation_bar.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/services/main/announcement/announcement_service.dart';
import 'package:suxingchahui/services/main/message/message_service.dart';
import 'package:suxingchahui/services/main/user/user_checkin_service.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/models/user/user.dart'; // 确保 User 模型已引入
import 'package:suxingchahui/widgets/components/badge/layout/update_button.dart';
import 'package:suxingchahui/widgets/components/badge/layout/message_badge.dart';
import 'package:suxingchahui/widgets/components/indicators/announcement_indicator.dart';
import 'package:suxingchahui/widgets/components/badge/layout/checkin_badge.dart';
import 'package:suxingchahui/widgets/ui/badges/safe_user_avatar.dart';

class TopNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogoTap;
  final VoidCallback onProfileTap;
  final AuthProvider authProvider;
  final MessageService messageService;
  final AnnouncementService announcementService;
  final UserCheckInService checkInService;

  const TopNavigationBar({
    super.key,
    required this.authProvider,
    required this.onLogoTap,
    required this.onProfileTap,
    required this.messageService,
    required this.announcementService,
    required this.checkInService,
  });

  @override
  Size get preferredSize {
    final ui.FlutterView? view = ui.PlatformDispatcher.instance.implicitView;
    if (view != null) {
      final bool isLandscape =
          view.physicalSize.width > view.physicalSize.height;
      if (DeviceUtils.isAndroid && isLandscape) {
        return Size.fromHeight(kToolbarHeight * 0.8);
      }
    }
    return Size.fromHeight(kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    final bool isActualAndroidLandscape = DeviceUtils.isAndroid &&
        (MediaQuery.of(context).orientation == Orientation.landscape);

    final double verticalPadding = isActualAndroidLandscape ? 4.0 : 8.0;
    final double iconSize = isActualAndroidLandscape ? 18.0 : 20.0;
    final double searchBarHeight = isActualAndroidLandscape ? 32.0 : 40.0;
    // avatarRadius 现在表示期望的 *可见图片内容* 的半径
    final double avatarRadius = isActualAndroidLandscape ? 12.0 : 14.0;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.grey[700]),
      title: _buildSearchBar(context, searchBarHeight, iconSize),
      titleSpacing: 8.0,
      actions: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: UpdateButton(),
          ),
        ),
        const SizedBox(width: 8),
        _buildAnnouncementIndicator(context, verticalPadding),
        const SizedBox(width: 8),
        _buildMessageBadge(context, verticalPadding),
        const SizedBox(width: 8),
        _buildCheckInBadge(context, verticalPadding),
        const SizedBox(width: 8),
        // 这里调用 _buildProfileAvatar, 它会返回带 Padding 的 SafeUserAvatar
        _buildProfileAvatar(context, avatarRadius, verticalPadding),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildCheckInBadge(BuildContext context, double padding) {
    if (authProvider.isLoggedIn) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: padding),
          child: CheckInBadge(
            checkInService: checkInService,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAnnouncementIndicator(BuildContext context, double padding) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: padding),
        child: AnnouncementIndicator(
          authProvider: authProvider,
          announcementService: announcementService,
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, double height, double iconSize) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => NavigationUtils.pushNamed(context, AppRoutes.searchGame),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.search_rounded,
                      color: Colors.grey[400], size: iconSize),
                ),
                Expanded(
                  child: Text(
                    '搜索游戏...',
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: iconSize * 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBadge(BuildContext context, double padding) {
    if (authProvider.isLoggedIn) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: padding),
          child: MessageBadge(
              messageService: messageService), // MessageBadge 内部处理状态
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // 重构后的 _buildProfileAvatar 方法
  Widget _buildProfileAvatar(BuildContext context, double imageContentRadius,
      double appBarActionVerticalPadding) {
    // 定义头像样式常量
    final Color avatarBorderColor = Color(0xFF2979FF);
    final double avatarBorderWidth = 1.5;
    // 这个背景色用于图片加载时的占位符背景，以及当 placeholder 是文本时的背景
    final Color avatarPlaceholderBackgroundColor = Colors.grey[100]!;

    // SafeUserAvatar 的 radius 参数应为 (期望的图片内容半径 + 边框宽度)
    // 这样能保证最终渲染出来的图片部分半径符合 imageContentRadius
    final double suaRadius = imageContentRadius + avatarBorderWidth;

    return Padding(
      // 这个 Padding 控制 SafeUserAvatar 在 AppBar actions 列表中的垂直对齐和间距
      padding: EdgeInsets.symmetric(
          vertical: appBarActionVerticalPadding, horizontal: 0),
      child: StreamBuilder<User?>(
        stream: authProvider.currentUserStream,
        initialData: authProvider.currentUser,
        builder: (context, currentUserSnapshot) {
          final User? currentUser = currentUserSnapshot.data;

          if (currentUser == null) {
            // 已登录，但用户信息尚未加载完成 (或异常情况)
            return SafeUserAvatar(
              key: const ValueKey('avatar_loading_user'),
              radius: suaRadius,
              onTap: onProfileTap,
              enableNavigation: false,
              borderColor: avatarBorderColor,
              borderWidth: avatarBorderWidth,
              backgroundColor: avatarPlaceholderBackgroundColor,
              placeholder: Icon(
                Icons.person_outline_rounded,
                size: imageContentRadius * 1.3,
                color: Colors.grey[400],
              ),
            );
          }

          // 用户信息已加载
          return SafeUserAvatar(
            key: ValueKey('avatar_user_${currentUser.id}'),
            userId: currentUser.id, // 可以传递 userId
            avatarUrl: currentUser.avatar,
            username: currentUser.username,
            radius: suaRadius,
            onTap: onProfileTap,
            enableNavigation: false,
            borderColor: avatarBorderColor,
            borderWidth: avatarBorderWidth,
            backgroundColor: avatarPlaceholderBackgroundColor,
          );
        },
      ),
    );
  }
}

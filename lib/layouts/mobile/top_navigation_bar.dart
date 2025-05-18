// lib/layouts/mobile/top_navigation_bar.dart
import 'dart:ui' as ui; // 导入 dart:ui
import 'package:flutter/material.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/components/badge/layout/update_button.dart';
import 'package:suxingchahui/widgets/components/badge/layout/message_badge.dart';
import 'package:suxingchahui/widgets/components/indicators/announcement_indicator.dart';
import 'package:suxingchahui/widgets/components/badge/layout/checkin_badge.dart';

class TopNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogoTap;
  final VoidCallback onProfileTap;
  final bool isLoggedIn;

  const TopNavigationBar(
      {super.key,
      required this.isLoggedIn,
      required this.onLogoTap,
      required this.onProfileTap});

  @override
  Size get preferredSize {
    // 尝试获取主视图
    final ui.FlutterView? view = ui.PlatformDispatcher.instance.implicitView;

    if (view != null) {
      // 使用视图的物理尺寸和设备像素比来判断方向（如果需要逻辑像素的话）
      // 但你这里是直接比较物理尺寸的宽高
      final bool isLandscape =
          view.physicalSize.width > view.physicalSize.height;
      if (DeviceUtils.isAndroid && isLandscape) {
        return Size.fromHeight(kToolbarHeight * 0.8);
      }
    }
    // 默认或获取视图失败的情况
    return Size.fromHeight(kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    final bool isActualAndroidLandscape = DeviceUtils.isAndroid &&
        (MediaQuery.of(context).orientation == Orientation.landscape);

    final double verticalPadding = isActualAndroidLandscape ? 4.0 : 8.0;
    final double iconSize = isActualAndroidLandscape ? 18.0 : 20.0;
    final double searchBarHeight = isActualAndroidLandscape ? 32.0 : 40.0;
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
        _buildProfileAvatar(context, avatarRadius, verticalPadding),
        const SizedBox(width: 16),
      ],
    );
  }

  // 签到Badge构建方法
  Widget _buildCheckInBadge(BuildContext context, double padding) {
    // 仅在登录时显示签到Badge
    if (isLoggedIn) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: padding),
          child: CheckInBadge(),
        ),
      );
    }
    return SizedBox.shrink();
  }

  // 添加公告指示器构建方法
  Widget _buildAnnouncementIndicator(BuildContext context, double padding) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: padding),
        child: const AnnouncementIndicator(),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, double height, double iconSize) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => NavigationUtils.pushNamed(
            context,
            AppRoutes.searchGame,
          ),
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
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[400],
                    size: iconSize,
                  ),
                ),
                Expanded(
                  child: Text(
                    '搜索游戏...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: iconSize * 0.7,
                    ),
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
    // 添加空值检查
    if (isLoggedIn) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: padding),
          child: MessageBadge(),
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildProfileAvatar(
      BuildContext context, double radius, double padding) {
    final double avatarSize = radius * 2; // 头像直径

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final User? currentUser = authProvider.currentUser;

        // 构建基础的头像容器 (带边框和点击)
        Widget buildAvatarContainer(Widget avatarContent) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: padding),
            child: GestureDetector(
              // 未登录时，点击通常是去登录页，已登录是去个人资料页
              // onProfileTap 的具体逻辑应该由调用者决定
              onTap: onProfileTap,
              child: Container(
                padding: EdgeInsets.all(2), // 边框空间
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF2979FF), // 统一用亮蓝色边框
                    width: 1.5,
                  ),
                ),
                child: avatarContent, // 里面塞头像具体内容
              ),
            ),
          );
        }

        // ---- 未登录状态 ----
        if (!isLoggedIn) {
          return buildAvatarContainer(
            CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey[100],
              child: Icon(
                Icons.person_rounded,
                size: radius * 1.3,
                color: Colors.grey[400],
              ),
            ),
          );
        }

        // 检查是否有有效的头像 URL
        final bool hasAvatar = currentUser?.avatar?.isNotEmpty ?? false;

        if (hasAvatar) {
          // ---- 有头像：使用 SafeCachedImage ----
          return buildAvatarContainer(
            // 用 ClipOval 保证 SafeCachedImage 是圆的
            ClipOval(
              child: SafeCachedImage(
                imageUrl:
                    currentUser!.avatar!, // 此时 currentUser 和 avatar 都不为 null
                width: avatarSize,
                height: avatarSize,
                fit: BoxFit.cover,
                memCacheHeight:
                    (avatarSize * MediaQuery.of(context).devicePixelRatio)
                        .round(), // 优化缓存尺寸
                memCacheWidth:
                    (avatarSize * MediaQuery.of(context).devicePixelRatio)
                        .round(), // 优化缓存尺寸
                // 注意：SafeCachedImage 本身没有 borderRadius，所以用 ClipOval 包裹
              ),
            ),
          );
        } else {
          // 使用更安全的判断：currentUser.username 是否有效
          final bool hasUsername = currentUser?.username.isNotEmpty ?? false;
          final String fallbackText =
              hasUsername ? currentUser!.username[0].toUpperCase() : '?';

          return buildAvatarContainer(
            CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey[100],
              child: Text(
                fallbackText,
                style: TextStyle(
                  fontSize: radius * 0.9, // 调整字体大小以适应圆圈
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

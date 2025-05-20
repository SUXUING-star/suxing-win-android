// lib/layouts/mobile/top_navigation_bar.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/models/user/user.dart'; // 确保 User 模型已引入
// import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 不再需要
// import 'package:provider/provider.dart'; // 不再需要
import 'package:suxingchahui/widgets/components/badge/layout/update_button.dart';
import 'package:suxingchahui/widgets/components/badge/layout/message_badge.dart';
import 'package:suxingchahui/widgets/components/indicators/announcement_indicator.dart';
import 'package:suxingchahui/widgets/components/badge/layout/checkin_badge.dart';

class TopNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogoTap;
  final VoidCallback onProfileTap;
  final AuthProvider authProvider;

  const TopNavigationBar({
    super.key,
    required this.authProvider,
    required this.onLogoTap,
    required this.onProfileTap,
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
        _buildMessageBadge(context, verticalPadding), // isLoggedIn 会在内部使用
        const SizedBox(width: 8),
        _buildCheckInBadge(context, verticalPadding), // isLoggedIn 会在内部使用
        const SizedBox(width: 8),
        _buildProfileAvatar(context, avatarRadius,
            verticalPadding), // isLoggedIn 和 currentUser 会在内部使用
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildCheckInBadge(BuildContext context, double padding) {
    if (authProvider.isLoggedIn) {
      // 直接使用传入的 isLoggedIn
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

  Widget _buildAnnouncementIndicator(BuildContext context, double padding) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: padding),
        child: AnnouncementIndicator(authProvider: authProvider),
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
                  padding: EdgeInsets.symmetric(horizontal: 12),
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
      // 直接使用传入的 isLoggedIn
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
    final double avatarSize = radius * 2;

    // 不再需要 Consumer，直接使用传入的 isLoggedIn 和 currentUser
    Widget buildAvatarContainer(Widget avatarContent) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: padding),
        child: GestureDetector(
          onTap: onProfileTap, // 直接使用传入的 onProfileTap
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF2979FF), width: 1.5),
            ),
            child: avatarContent,
          ),
        ),
      );
    }

    if (!authProvider.isLoggedIn) {
      // 直接使用传入的 isLoggedIn
      return buildAvatarContainer(
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[100],
          child: Icon(Icons.person_rounded,
              size: radius * 1.3, color: Colors.grey[400]),
        ),
      );
    }

    // 已登录状态，使用传入的 currentUser
    final User? currentUser = authProvider.currentUser;
    final bool hasAvatar = currentUser?.avatar?.isNotEmpty ?? false;

    if (hasAvatar) {
      return buildAvatarContainer(
        ClipOval(
          child: SafeCachedImage(
            imageUrl: currentUser!.avatar!,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            memCacheHeight:
                (avatarSize * MediaQuery.of(context).devicePixelRatio).round(),
            memCacheWidth:
                (avatarSize * MediaQuery.of(context).devicePixelRatio).round(),
          ),
        ),
      );
    } else {
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
                fontSize: radius * 0.9,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700),
          ),
        ),
      );
    }
  }
}

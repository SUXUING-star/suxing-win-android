// lib/widgets/ui/badge/safe_user_avatar.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/routes/app_routes.dart'; // 假设路径正确
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 假设路径正确
import '../image/safe_cached_image.dart'; // 假设路径正确

/// 安全的用户头像组件
///
/// 显示用户头像，并可在左上角叠加管理员标识。
class SafeUserAvatar extends StatelessWidget {
  /// 用于导航到用户个人资料页的ID。
  final String? userId;
  /// 头像图片的URL。
  final String? avatarUrl;
  /// 用户名，用于在没有头像URL时生成占位符。
  final String? username;
  /// 头像的半径。
  final double radius;
  /// 是否启用点击头像导航到用户资料页的功能。
  final bool enableNavigation;
  /// 自定义的点击头像回调。
  final VoidCallback? onTap;
  /// 当没有 `avatarUrl` 时，显示的自定义占位Widget。
  final Widget? placeholder;
  /// 头像的边框颜色。
  final Color? borderColor;
  /// 头像的边框宽度。
  final double? borderWidth;
  /// 头像组件整体的背景色（例如，在没有图片或图片透明时显示）。
  final Color? backgroundColor;

  /// 是否为普通管理员。
  final bool isAdmin;
  /// 是否为超级管理员（优先于isAdmin显示）。
  final bool isSuperAdmin;

  const SafeUserAvatar({
    super.key,
    this.userId,
    this.avatarUrl,
    this.username,
    this.radius = 20,
    this.enableNavigation = true,
    this.onTap,
    this.placeholder,
    this.borderColor,
    this.borderWidth,
    this.backgroundColor,
    this.isAdmin = false,
    this.isSuperAdmin = false,
  });

  void _navigateToProfile(BuildContext context) {
    if (userId != null) {
      NavigationUtils.pushNamed(
        context,
        AppRoutes.openProfile,
        arguments: userId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = radius * 2;
    // 调整挂件相关尺寸
    final double badgeContainerHorizontalPadding = radius * 0.15;
    final double badgeContainerVerticalPadding = radius * 0.08;
    final double badgeIconSize = radius * 0.45;
    final double badgeFontSize = radius * 0.35;
    final double badgeIconTextSpacing = radius * 0.08;
    // 挂件的偏移量
    final double badgeOffsetHorizontal = radius * -0.2;
    final double badgeOffsetVertical = radius * -0.25;

    Widget avatarCore;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      avatarCore = SafeCachedImage(
        imageUrl: avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(radius),
      );
    } else {
      final String displayChar =
      (username?.isNotEmpty == true) ? username![0].toUpperCase() : '?';
      avatarCore = SizedBox(
        width: size,
        height: size,
        child: Center(
          child: placeholder ??
              Text(
                displayChar,
                style: TextStyle(
                  fontSize: radius * 0.9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
        ),
      );
    }

    Widget avatarWithBackgroundAndClip = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.grey.shade200,
        border: borderColor != null && borderWidth != null
            ? Border.all(color: borderColor!, width: borderWidth!)
            : null,
      ),
      child: ClipOval(
        child: avatarCore,
      ),
    );

    // --- 构建更明确的管理员标识 ---
    Widget? adminBadgeWidget;
    if (isSuperAdmin || isAdmin) {
      String badgeText;
      IconData badgeIcon;
      Color badgeBackgroundColor;
      Color badgeForegroundColor;

      if (isSuperAdmin) {
        badgeText = "超管";
        badgeIcon = Icons.workspace_premium_rounded; // 例如：皇冠
        badgeBackgroundColor = Colors.amber[700]!;
        badgeForegroundColor = Colors.white;
      } else { // isAdmin
        badgeText = "管理";
        badgeIcon = Icons.shield_outlined; // 例如：盾牌
        badgeBackgroundColor = Colors.blue[600]!;
        badgeForegroundColor = Colors.white;
      }

      adminBadgeWidget = Container(
        // 容器大小会由内部 Row 和 Padding 决定，这里可以不显式设置宽高
        // width: badgeContainerWidth,
        // height: badgeContainerHeight,
        padding: EdgeInsets.symmetric(
            horizontal: badgeContainerHorizontalPadding,
            vertical: badgeContainerVerticalPadding),
        decoration: BoxDecoration(
          color: badgeBackgroundColor.withOpacity(0.95), // 背景更实一点
          borderRadius: BorderRadius.circular(radius * 0.3), // 圆角标签
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 2,
              offset: Offset(0, 1),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // 重要：让Row包裹内容
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              badgeIcon,
              color: badgeForegroundColor,
              size: badgeIconSize,
            ),
            SizedBox(width: badgeIconTextSpacing),
            Text(
              badgeText,
              style: TextStyle(
                color: badgeForegroundColor,
                fontWeight: FontWeight.bold,
                fontSize: badgeFontSize,
                letterSpacing: 0.5, // 可选：增加一点字母间距
              ),
            ),
          ],
        ),
      );
    }
    // --- 结束构建 ---

    Widget avatarStack = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        avatarWithBackgroundAndClip,
        if (adminBadgeWidget != null)
          Positioned(
            top: badgeOffsetVertical,
            left: badgeOffsetHorizontal,
            // 如果希望挂件宽度不影响其基于左侧的定位，可以考虑用 Transform.translate
            // child: Transform.translate(
            //   offset: Offset(badgeOffsetHorizontal, badgeOffsetVertical),
            //   child: adminBadgeWidget,
            // ),
            child: adminBadgeWidget,
          ),
      ],
    );

    if (onTap != null || (enableNavigation && userId != null)) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap ??
              (enableNavigation
                  ? () => _navigateToProfile(context)
                  : null),
          child: avatarStack,
        ),
      );
    }

    return avatarStack;
  }
}
// lib/widgets/ui/badge/safe_user_avatar.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import '../image/safe_cached_image.dart';

class SafeUserAvatar extends StatelessWidget {
  final String? userId;
  final String? avatarUrl;
  final String? username;
  final double radius;
  final bool enableNavigation;
  final VoidCallback? onTap;
  final Widget? placeholder; // 自定义占位符 Widget (当 avatarUrl 为空时)
  final Color? borderColor;
  final double? borderWidth;
  final Color? backgroundColor; // 头像组件整体背景色，也用于 SafeCachedImage 的占位符背景

  final bool isAdmin;
  final bool isSuperAdmin;

  final int? memCacheWidth; // 内存缓存宽度 (物理像素)
  final int? memCacheHeight; // 内存缓存高度 (物理像素)

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
    this.backgroundColor, // 接收 backgroundColor
    this.isAdmin = false,
    this.isSuperAdmin = false,
    this.memCacheWidth,
    this.memCacheHeight,
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
    final double size = radius * 2; // 头像的直径

    // --- 徽章相关尺寸计算 ---
    final double badgeContainerHorizontalPadding = radius * 0.15;
    final double badgeContainerVerticalPadding = radius * 0.08;
    final double badgeIconSize = radius * 0.45;
    final double badgeFontSize = radius * 0.35;
    final double badgeIconTextSpacing = radius * 0.08;
    final double badgeOffsetHorizontal = radius * -0.2; // 徽章相对于左上角的水平偏移
    final double badgeOffsetVertical = radius * -0.25; // 徽章相对于左上角的垂直偏移

    // --- 构建头像核心内容 (SafeCachedImage 或占位符) ---
    Widget avatarCore;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      // 计算传递给 SafeCachedImage 的 memCacheWidth 和 memCacheHeight
      int? finalMemCacheWidth = memCacheWidth;
      int? finalMemCacheHeight = memCacheHeight;

      if (finalMemCacheWidth == null && finalMemCacheHeight == null) {
        // 如果外部未指定缓存尺寸，则根据头像的实际显示尺寸 (size) 和设备像素比计算
        final dpr = MediaQuery.of(context).devicePixelRatio;
        final physicalSize = (size * dpr).round();
        finalMemCacheWidth = physicalSize;
        finalMemCacheHeight = physicalSize; // 头像通常是方形的
      }

      avatarCore = SafeCachedImage(
        imageUrl: avatarUrl!,
        width: size, // SafeCachedImage 的显示尺寸
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: finalMemCacheWidth, // 传递计算好的缓存宽度
        memCacheHeight: finalMemCacheHeight, // 传递计算好的缓存高度
        backgroundColor: backgroundColor,
      );
    } else {
      // 没有头像 URL，显示占位符
      final String displayChar =
          (username?.isNotEmpty == true) ? username![0].toUpperCase() : '?';
      avatarCore = SizedBox(
        width: size,
        height: size,
        child: Center(
          child: placeholder ?? // 优先使用外部传入的 placeholder
              Text(
                displayChar,
                style: TextStyle(
                  fontSize: radius * 0.9, // 根据半径调整字体大小
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700, // 默认占位符文本颜色
                ),
              ),
        ),
      );
    }

    // --- 使用 Container 添加背景色、边框，并用 ClipOval 裁剪成圆形 ---
    Widget avatarWithBackgroundAndClip = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 如果有头像URL且加载成功，这个背景色会被图片覆盖；
        // 如果没有头像URL，或者图片加载失败/透明，这个背景色会显示出来。
        color: backgroundColor ?? Colors.grey.shade200, // 默认背景色
        border: borderColor != null && borderWidth != null
            ? Border.all(color: borderColor!, width: borderWidth!)
            : null,
      ),
      child: ClipOval(
        // 确保内容（图片或占位符）被裁剪成圆形
        child: avatarCore,
      ),
    );

    // --- 构建管理员/超级管理员徽章 ---
    Widget? adminBadgeWidget;
    if (isSuperAdmin || isAdmin) {
      String badgeText;
      IconData badgeIcon;
      Color badgeBackgroundColor;
      Color badgeForegroundColor;

      if (isSuperAdmin) {
        badgeText = "超管";
        badgeIcon = Icons.workspace_premium_rounded; // 例如：皇冠或认证图标
        badgeBackgroundColor = Colors.amber[700]!; // 超管用更醒目的颜色
        badgeForegroundColor = Colors.white;
      } else {
        // isAdmin
        badgeText = "管理";
        badgeIcon = Icons.shield_outlined; // 例如：盾牌
        badgeBackgroundColor = Colors.blue[600]!;
        badgeForegroundColor = Colors.white;
      }

      adminBadgeWidget = Container(
        padding: EdgeInsets.symmetric(
            horizontal: badgeContainerHorizontalPadding,
            vertical: badgeContainerVerticalPadding),
        decoration: BoxDecoration(
          color: badgeBackgroundColor.withSafeOpacity(0.95), // 背景色，可以带一点透明
          borderRadius: BorderRadius.circular(radius * 0.3), // 徽章的圆角
          boxShadow: [
            // 给徽章一点阴影，增加立体感
            BoxShadow(
              color: Colors.black.withSafeOpacity(0.25),
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // 让 Row 包裹其内容物
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              badgeIcon,
              color: badgeForegroundColor,
              size: badgeIconSize,
            ),
            SizedBox(width: badgeIconTextSpacing), // 图标和文字之间的间距
            Text(
              badgeText,
              style: TextStyle(
                color: badgeForegroundColor,
                fontWeight: FontWeight.bold,
                fontSize: badgeFontSize,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    // --- 使用 Stack 组合头像和徽章 ---
    Widget avatarStack = Stack(
      clipBehavior: Clip.none, // 允许徽章超出头像边界显示
      alignment: Alignment.center, // 头像居中
      children: [
        avatarWithBackgroundAndClip, // 基础头像 (已包含背景和裁剪)
        if (adminBadgeWidget != null)
          Positioned(
            // 根据计算的偏移量定位徽章
            // top 和 left 是相对于 Stack 中心点的头像左上角而言的
            // 如果希望徽章在右下角，可以调整为 bottom 和 right
            top: badgeOffsetVertical,
            left: badgeOffsetHorizontal,
            child: adminBadgeWidget,
          ),
      ],
    );

    // --- 添加点击交互 ---
    if (onTap != null || (enableNavigation && userId != null)) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap ?? // 优先使用外部传入的 onTap
              (enableNavigation // 其次判断是否启用导航
                  ? () => _navigateToProfile(context) // 执行导航
                  : null), // 如果不启用导航且没有 onTap，则不可点击
          child: avatarStack,
        ),
      );
    }

    return avatarStack; // 如果不可点击，直接返回 Stack
  }
}

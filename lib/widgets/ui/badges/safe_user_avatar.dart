// lib/widgets/ui/badge/safe_user_avatar.dart

/// 该文件定义了 SafeUserAvatar 组件，一个用于安全显示用户头像的 StatelessWidget。
/// 该组件支持显示头像、管理员徽章和导航功能。
library;


import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/routes/app_routes.dart'; // 导入应用路由
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart'; // 导入安全缓存图片组件

/// `SafeUserAvatar` 类：一个用于安全显示用户头像的组件。
///
/// 该组件根据用户ID、头像URL和角色信息显示头像，并提供点击导航功能。
class SafeUserAvatar extends StatelessWidget {
  final String? userId; // 用户ID
  final String? avatarUrl; // 头像的网络 URL
  final String? username; // 用户名
  final double radius; // 头像半径
  final bool enableNavigation; // 是否启用点击导航到用户资料页
  final VoidCallback? onTap; // 点击头像的回调
  final Widget? placeholder; // 当 avatarUrl 为空时显示的自定义占位符
  final Color? borderColor; // 头像边框颜色
  final double? borderWidth; // 头像边框宽度
  final Color? backgroundColor; // 头像组件背景色，也用于 SafeCachedImage 的占位符背景

  final bool isAdmin; // 用户是否为管理员
  final bool isSuperAdmin; // 用户是否为超级管理员

  final int? memCacheWidth; // 内存缓存宽度（物理像素）
  final int? memCacheHeight; // 内存缓存高度（物理像素）

  /// 构造函数。
  ///
  /// [userId]：用户ID。
  /// [avatarUrl]：头像 URL。
  /// [username]：用户名。
  /// [radius]：半径。
  /// [enableNavigation]：是否启用导航。
  /// [onTap]：点击回调。
  /// [placeholder]：占位符。
  /// [borderColor]：边框颜色。
  /// [borderWidth]：边框宽度。
  /// [backgroundColor]：背景色。
  /// [isAdmin]：是否管理员。
  /// [isSuperAdmin]：是否超级管理员。
  /// [memCacheWidth]：内存缓存宽度。
  /// [memCacheHeight]：内存缓存高度。
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
    this.memCacheWidth,
    this.memCacheHeight,
  });

  /// 导航到用户资料页面。
  ///
  /// [context]：Build 上下文。
  void _navigateToProfile(BuildContext context) {
    if (userId != null) {
      NavigationUtils.pushNamed(
        context,
        AppRoutes.openProfile, // 导航到用户资料路由
        arguments: userId, // 传递用户ID参数
      );
    }
  }

  /// 构建用户头像组件。
  @override
  Widget build(BuildContext context) {
    final double size = radius * 2; // 头像的直径

    final double badgeContainerHorizontalPadding = radius * 0.15; // 徽章容器水平内边距
    final double badgeContainerVerticalPadding = radius * 0.08; // 徽章容器垂直内边距
    final double badgeIconSize = radius * 0.45; // 徽章图标大小
    final double badgeFontSize = radius * 0.35; // 徽章字体大小
    final double badgeIconTextSpacing = radius * 0.08; // 徽章图标与文本间距
    final double badgeOffsetHorizontal = radius * -0.2; // 徽章水平偏移
    final double badgeOffsetVertical = radius * -0.25; // 徽章垂直偏移

    Widget avatarCore; // 头像核心内容组件
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      int? finalMemCacheWidth = memCacheWidth; // 最终内存缓存宽度
      int? finalMemCacheHeight = memCacheHeight; // 最终内存缓存高度

      if (finalMemCacheWidth == null && finalMemCacheHeight == null) {
        final dpr = MediaQuery.of(context).devicePixelRatio; // 设备像素比
        final physicalSize = (size * dpr).round(); // 物理尺寸
        finalMemCacheWidth = physicalSize; // 根据物理尺寸设置缓存宽度
        finalMemCacheHeight = physicalSize; // 根据物理尺寸设置缓存高度
      }

      avatarCore = SafeCachedImage(
        imageUrl: avatarUrl!, // 图片 URL
        width: size, // 显示宽度
        height: size, // 显示高度
        fit: BoxFit.cover, // 填充模式
        memCacheWidth: finalMemCacheWidth, // 内存缓存宽度
        memCacheHeight: finalMemCacheHeight, // 内存缓存高度
        backgroundColor: backgroundColor, // 背景色
      );
    } else {
      final String displayChar = (username?.isNotEmpty == true)
          ? username![0].toUpperCase()
          : '?'; // 显示字符
      avatarCore = SizedBox(
        width: size, // 宽度
        height: size, // 高度
        child: Center(
          child: placeholder ?? // 自定义占位符或默认文本
              Text(
                displayChar,
                style: TextStyle(
                  fontSize: radius * 0.9, // 字体大小
                  fontWeight: FontWeight.bold, // 字体粗细
                  color: Colors.grey.shade700, // 文本颜色
                ),
              ),
        ),
      );
    }

    Widget avatarWithBackgroundAndClip = Container(
      width: size, // 宽度
      height: size, // 高度
      decoration: BoxDecoration(
        shape: BoxShape.circle, // 形状为圆形
        color: backgroundColor ?? Colors.grey.shade200, // 背景色
        border: borderColor != null && borderWidth != null // 边框
            ? Border.all(color: borderColor!, width: borderWidth!)
            : null,
      ),
      child: ClipOval(
        child: avatarCore, // 裁剪为圆形
      ),
    );

    Widget? adminBadgeWidget; // 管理员徽章组件
    if (isSuperAdmin || isAdmin) {
      String badgeText; // 徽章文本
      IconData badgeIcon; // 徽章图标
      Color badgeBackgroundColor; // 徽章背景色
      Color badgeForegroundColor; // 徽章前景色

      if (isSuperAdmin) {
        badgeText = "超管";
        badgeIcon = Icons.workspace_premium_rounded;
        badgeBackgroundColor = Colors.amber[700]!;
        badgeForegroundColor = Colors.white;
      } else {
        badgeText = "管理";
        badgeIcon = Icons.shield_outlined;
        badgeBackgroundColor = Colors.blue[600]!;
        badgeForegroundColor = Colors.white;
      }

      adminBadgeWidget = Container(
        padding: EdgeInsets.symmetric(
            horizontal: badgeContainerHorizontalPadding,
            vertical: badgeContainerVerticalPadding), // 徽章内边距
        decoration: BoxDecoration(
          color: badgeBackgroundColor.withSafeOpacity(0.95), // 背景色
          borderRadius: BorderRadius.circular(radius * 0.3), // 圆角
          boxShadow: [
            // 阴影
            BoxShadow(
              color: Colors.black.withSafeOpacity(0.25),
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // 行主轴尺寸最小化以适应内容
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              badgeIcon, // 徽章图标
              color: badgeForegroundColor, // 徽章颜色
              size: badgeIconSize, // 徽章大小
            ),
            SizedBox(width: badgeIconTextSpacing), // 图标和文本间距
            Text(
              badgeText, // 徽章文本
              style: TextStyle(
                color: badgeForegroundColor, // 字体颜色
                fontWeight: FontWeight.bold, // 字体粗细
                fontSize: badgeFontSize, // 字体大小
                letterSpacing: 0.5, // 字间距
              ),
            ),
          ],
        ),
      );
    }

    Widget avatarStack = Stack(
      clipBehavior: Clip.none, // 允许子组件超出 Stack 边界
      alignment: Alignment.center, // Stack 内容居中
      children: [
        avatarWithBackgroundAndClip, // 基础头像
        if (adminBadgeWidget != null)
          Positioned(
            top: badgeOffsetVertical, // 顶部偏移
            left: badgeOffsetHorizontal, // 左侧偏移
            child: adminBadgeWidget, // 管理员徽章
          ),
      ],
    );

    if (onTap != null || (enableNavigation && userId != null)) {
      // 如果可点击或启用导航且有用户ID
      return MouseRegion(
        cursor: SystemMouseCursors.click, // 鼠标悬停显示点击光标
        child: GestureDetector(
          onTap: onTap ?? // 优先使用外部点击回调
              (enableNavigation // 其次判断是否启用导航
                  ? () => _navigateToProfile(context) // 执行导航
                  : null), // 无效时不可点击
          child: avatarStack, // 包含头像和徽章的 Stack
        ),
      );
    }

    return avatarStack; // 不可点击时直接返回 Stack
  }
}

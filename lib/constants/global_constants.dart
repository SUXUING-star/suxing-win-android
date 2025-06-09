// lib/constants/global_constants.dart

/// 该文件定义了全局常量，包含应用链接、技术栈信息、默认图片资源、UI 尺寸和颜色等。
library;

import 'package:flutter/material.dart'; // Flutter UI 框架

/// `GlobalConstants` 类：定义全局常量。
///
/// 该类包含应用的基础信息、外部链接、默认资源路径、UI 样式配置等。
class GlobalConstants {
  static const String donationUrl = 'https://xingsu.fun'; // 捐赠链接
  static const String feedbackUrl = 'https://xingsu.fun'; // 反馈链接
  static const String githubUrl =
      'https://github.com/SUXUING-star/suxing-win-android'; // GitHub 仓库链接
  static const String bUrl =
      'https://space.bilibili.com/32892805?spm_id_from=333.1007.0.0'; // Bilibili 空间链接

  static const String groupNumber = '829701655'; // QQ 群号
  static const String qrCodeAssetPath =
      'assets/images/qq/qq.png'; // QQ 群二维码图片资源路径
  static const String appName = '宿星茶会'; // 应用名称
  static const String appNameAndroid = '$appName（安卓版）'; // 安卓版应用名称
  static const String appNameWindows = '$appName（Windows）'; // Windows 版应用名称
  static const String appIcon = 'assets/images/icons/app_icon.jpg'; // 应用图标路径

  /// 技术栈信息列表。
  static const List<Map<String, dynamic>> techStacks = [
    {
      "title": "本项目全栈开发技术",
      "items": [
        {"name": "Dart", "desc": "客户端开发"},
        {"name": "Golang", "desc": "服务端开发"},
      ]
    }
  ];

  /// 默认背景图片列表。
  static const List<String> defaultBackgroundImages = [
    'assets/images/background/bg-1.jpg',
    'assets/images/background/bg-2.jpg',
  ];

  /// 默认旋转后的背景图片列表。
  static const List<String> defaultBackgroundImagesRotated = [
    'assets/images/background/bg-1rotate.jpg',
    'assets/images/background/bg-2rotate.jpg',
  ];

  static const int defaultParticleCount = 30; // 默认粒子数量

  static const String initScreenGifFirst =
      'assets/images/menu/cappo.gif'; // 初始化屏幕 GIF 1
  static const String initScreenGifSecond =
      'assets/images/menu/cappo1.gif'; // 初始化屏幕 GIF 2

  static const String defaultBannerImage =
      'assets/images/banner/banner_image.png'; // 默认 Banner 图片

  /// 默认导航页面颜色列表。
  static const List<Color> defaultNavPageColors = [
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFF03A9F4),
  ];

  /// 默认侧边栏导航项列表。
  static List<Map<String, dynamic>> defaultSideBarNavItems() {
    return [
      {'icon': Icons.home_rounded, 'label': '首页', 'index': 0},
      {'icon': Icons.games_rounded, 'label': '游戏', 'index': 1},
      {'icon': Icons.forum_rounded, 'label': '论坛', 'index': 2},
      {'icon': Icons.rocket_launch, 'label': '动态', 'index': 3},
      {'icon': Icons.link_rounded, 'label': '外部', 'index': 4},
    ];
  }

  /// 默认侧边栏颜色列表。
  static const List<Color> defaultSideBarColors = [
    Color(0xFFD8FFEF),
    Color(0x000000ff),
  ];

  /// 桌面端的 AppBar 高度比例。
  static const double appBarDesktopToolbarHeightFactor = 0.75;

  /// 桌面端的底部线条高度。
  static const double appBarDesktopBottomHeight = 2.0;

  /// 桌面端的标题字体大小。
  static const double appBarDesktopFontSize = 14.0;

  /// Android 横屏的 AppBar 高度比例。
  static const double appBarAndroidLandscapeToolbarHeightFactor = 0.8;

  /// Android 横屏的底部线条高度。
  static const double appBarAndroidLandscapeBottomHeight = 2.0;

  /// Android 横屏的标题字体大小。
  static const double appBarAndroidLandscapeFontSize = 14.0;

  /// 默认 AppBar 底部线条高度。
  static const double defaultAppBarBottomHeight = 4.0;

  /// 默认 AppBar 字体大小。
  static const double defaultAppBarFontSize = 16.0;

  /// 默认 AppBar 颜色列表。
  static const List<Color> defaultAppBarColors = [
    Color(0x000000FF),
    Color(0xFFD8FFEF),
    Color(0x000000FF),
  ];
}

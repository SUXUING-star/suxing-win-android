// lib/utils/device_utils.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DeviceUtils {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isDesktop => !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  // 侧边栏宽度，用于在Windows平台计算布局
  static const double sidebarWidth = 260.0;

  // 判断是否横屏
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // 判断是否竖屏
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // 常用组合判断
  static bool isAndroidLandscape(BuildContext context) {
    return isAndroid && isLandscape(context);
  }

  static bool isAndroidPortrait(BuildContext context) {
    return isAndroid && isPortrait(context);
  }

  // 获取基础尺寸
  static double getToolbarHeight(BuildContext context) {
    return isAndroidLandscape(context) ? kToolbarHeight * 0.8 : kToolbarHeight;
  }

  static double getIconSize(BuildContext context) {
    return isAndroidLandscape(context) ? 18.0 : 20.0;
  }

  static double getPadding(BuildContext context) {
    return isAndroidLandscape(context) ? 4.0 : 8.0;
  }

  // 获取可用内容宽度（考虑侧边栏）
  static double getAvailableContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return isWindows ? screenWidth - sidebarWidth : screenWidth;
  }

  static double calculateCardRatio(BuildContext context) {
    // 获取可用宽度（如果是Windows平台，需要减去侧边栏宽度）
    final availableWidth = getAvailableContentWidth(context);
    final horizontalPadding = 16.0; // 总的左右内边距
    final crossAxisSpacing = 8.0;

    // 计算一行可以放下多少卡片
    final maxCardWidth = 250.0; // GridView的maxCrossAxisExtent
    final cardsPerRow = (availableWidth / (maxCardWidth + crossAxisSpacing)).floor();
    final actualCardWidth = (availableWidth - horizontalPadding - (crossAxisSpacing * (cardsPerRow - 1))) / cardsPerRow;

    // 计算卡片所需高度（使用更宽松的间距）
    final imageHeight = 160.0; // GameCard中的固定图片高度
    final contentPadding = 24.0; // 从16.0增加到24.0
    final titleHeight = isAndroid && isPortrait(context) ? 24.0 : 28.0; // 标题高度增加
    final summaryHeight = isAndroid && isPortrait(context) ? 40.0 : 44.0; // 摘要高度增加
    final statsHeight = 32.0; // 从24.0增加到32.0
    final additionalSpacing = 16.0; // 为了更好的视觉效果添加额外间距

    final minCardHeight = imageHeight + contentPadding + titleHeight + summaryHeight + statsHeight + additionalSpacing;

    // 添加缩放因子，使卡片略高一些
    final scalingFactor = 1.2; // 使卡片高度增加20%

    final adjustedCardHeight = minCardHeight * scalingFactor;

    // 计算并返回纵横比
    double ratio = actualCardWidth / adjustedCardHeight;

    // 应用最小和最大约束
    ratio = ratio.clamp(0.65, 0.8);

    // 对于Android纵向模式，我们需要更小的比例
    if (isAndroid && isPortrait(context)) {
      ratio = ratio.clamp(0.60, 0.65);
    }

    return ratio;
  }
}
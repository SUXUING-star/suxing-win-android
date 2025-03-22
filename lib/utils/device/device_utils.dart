// lib/utils/device/device_utils.dart
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DeviceUtils {
  static bool get isWeb => kIsWeb;
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = sqrt(size.width * size.width + size.height * size.height);
    return diagonal > 1100; // Approximately 7-inch diagonal
  }
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isDesktop => !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  // 判断是否横屏
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // 判断是否竖屏
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  // Window state for desktop
  static bool get isFullScreen {
    if (isDesktop) {
      // Note: This would require a plugin like window_manager for Flutter desktop
      // to accurately determine if the window is fullscreen
      // For now we'll return a placeholder
      return false;
    }
    return false;
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

  // 获取面板宽度 - 根据屏幕尺寸自适应
  static double getSidePanelWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 在小屏幕上使用更窄的面板
    if (screenWidth < 600) {
      return 180;
    }
    // 在中等屏幕上使用中等宽度
    else if (screenWidth < 1200) {
      return 200;
    }
    // 在大屏幕上使用更宽的面板
    else {
      return 220;
    }
  }

  // 获取可用内容宽度 - 考虑面板情况
  static double getAvailableContentWidth(BuildContext context, {bool withPanels = false, bool leftPanelVisible = true, bool rightPanelVisible = true}) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 如果需要考虑面板，则减去面板宽度
    if (withPanels && isDesktop) {
      double panelWidth = getSidePanelWidth(context);
      double deduction = 0;

      if (leftPanelVisible) {
        deduction += panelWidth;
      }

      if (rightPanelVisible) {
        deduction += panelWidth;
      }

      return screenWidth - deduction;
    }

    return screenWidth;
  }

  // 计算一行能容纳的卡片数量
  static int calculateCardsPerRow(BuildContext context, {bool withPanels = false, bool leftPanelVisible = false, bool rightPanelVisible = false}) {
    final availableWidth = getAvailableContentWidth(
        context,
        withPanels: withPanels,
        leftPanelVisible: leftPanelVisible,
        rightPanelVisible: rightPanelVisible
    );

    final horizontalPadding = 16.0; // 总的左右内边距
    final crossAxisSpacing = 8.0;
    final effectiveWidth = availableWidth - horizontalPadding;

    // 根据屏幕宽度动态调整卡片宽度
    double targetCardWidth;
    if (availableWidth < 600) {
      targetCardWidth = 160; // 小屏幕使用更窄的卡片
    } else if (availableWidth < 900) {
      targetCardWidth = 180; // 中小屏幕
    } else if (availableWidth < 1200) {
      targetCardWidth = 200; // 中屏幕
    } else {
      targetCardWidth = 220; // 大屏幕使用更宽的卡片
    }

    // 计算可容纳的卡片数量
    int cardsPerRow = ((effectiveWidth + crossAxisSpacing) / (targetCardWidth + crossAxisSpacing)).floor();

    // 保证至少有1张卡片
    return cardsPerRow > 0 ? cardsPerRow : 1;
  }

  // 计算卡片高度
  static double calculateCardHeight(BuildContext context, bool showTags, bool isCompact) {
    // 基础组件高度
    final imageHeight = isCompact ? 140.0 : 160.0;
    final titleHeight = isCompact ? 22.0 : 24.0;
    final summaryHeight = isAndroidPortrait(context) ?
    (isCompact ? 18.0 : 20.0) : (isCompact ? 36.0 : 40.0);
    final tagsHeight = showTags ? (isCompact ? 24.0 : 28.0) : 0.0;
    final statsHeight = isCompact ? 24.0 : 28.0;
    final padding = isCompact ? 16.0 : 20.0;

    // 总高度
    return imageHeight + titleHeight + summaryHeight + tagsHeight + statsHeight + padding;
  }

  // 改进后的卡片比例计算方法
  static double calculateCardRatio(BuildContext context, {
    bool withPanels = false,
    bool leftPanelVisible = false,
    bool rightPanelVisible = false,
    bool showTags = true
  }) {
    // 计算一行可容纳的卡片数量
    final cardsPerRow = calculateCardsPerRow(
        context,
        withPanels: withPanels,
        leftPanelVisible: leftPanelVisible,
        rightPanelVisible: rightPanelVisible
    );

    // 获取可用宽度
    final availableWidth = getAvailableContentWidth(
        context,
        withPanels: withPanels,
        leftPanelVisible: leftPanelVisible,
        rightPanelVisible: rightPanelVisible
    );

    // 计算实际卡片宽度
    final horizontalPadding = 16.0;
    final crossAxisSpacing = 8.0;
    final actualCardWidth = (availableWidth - horizontalPadding - (crossAxisSpacing * (cardsPerRow - 1))) / cardsPerRow;

    // 确定卡片是否应该使用紧凑模式
    final isCompact = (cardsPerRow > 3) || (actualCardWidth < 180);

    // 计算卡片所需高度
    final cardHeight = calculateCardHeight(context, showTags, isCompact);

    // 计算并返回纵横比
    double ratio = actualCardWidth / cardHeight;

    // 打印计算信息用于调试
    print('屏幕宽度: ${MediaQuery.of(context).size.width}, '
        '有效宽度: $availableWidth, '
        '卡片数: $cardsPerRow, '
        '卡片宽度: $actualCardWidth, '
        '卡片高度: $cardHeight, '
        '比例: $ratio');

    // 约束比例在合理范围内
    double minRatio, maxRatio;

    if (isAndroidPortrait(context)) {
      minRatio = 0.58;
      maxRatio = 0.68;
    } else {
      minRatio = 0.62;
      maxRatio = 0.75;
    }

    return ratio.clamp(minRatio, maxRatio);
  }

  // 为热门/最新列表计算卡片比例
  static double calculateSimpleCardRatio(BuildContext context, {bool showTags = true}) {
    return calculateCardRatio(context, withPanels: false, showTags: showTags);
  }

  // 为游戏列表计算卡片比例
  static double calculateGameListCardRatio(BuildContext context, bool leftPanelVisible, bool rightPanelVisible, {bool showTags = true}) {
    return calculateCardRatio(
        context,
        withPanels: true,
        leftPanelVisible: leftPanelVisible,
        rightPanelVisible: rightPanelVisible,
        showTags: showTags
    );
  }

  // 原有的帖子卡片比例计算
  static double calculatePostCardRatio(BuildContext context) {
    // 获取可用宽度
    final availableWidth = getAvailableContentWidth(context);
    final horizontalPadding = 16.0; // 总的左右内边距
    final crossAxisSpacing = 16.0;

    // 计算一行可以放下多少卡片
    final cardsPerRow = 2; // 固定每行2个
    final actualCardWidth = (availableWidth - horizontalPadding - (crossAxisSpacing * (cardsPerRow - 1))) / cardsPerRow;

    // 计算卡片所需高度
    final titleHeight = isAndroid && isPortrait(context) ? 24.0 : 28.0;
    final contentHeight = isAndroid && isPortrait(context) ? 48.0 : 52.0; // 两行内容
    final infoHeight = 36.0; // 用户信息和统计信息
    final tagsHeight = 32.0; // 标签行高度
    final padding = 24.0; // 内边距

    // 最小卡片高度，不包括标签（因为标签可能不存在）
    final minCardHeight = titleHeight + contentHeight + infoHeight + padding;

    // 考虑标签的最大高度
    final maxCardHeight = minCardHeight + tagsHeight;

    // 计算并返回纵横比
    double ratio = actualCardWidth / maxCardHeight;

    // 应用最小和最大约束
    ratio = ratio.clamp(1.8, 2.2);

    // 对于Android纵向模式，调整比例
    if (isAndroid && isPortrait(context)) {
      ratio = ratio.clamp(1.6, 1.8);
    }

    return ratio;
  }
}
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
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

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

  static bool isDesktopScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1000;
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
  static double getAvailableContentWidth(BuildContext context,
      {bool withPanels = false,
      bool leftPanelVisible = true,
      bool rightPanelVisible = true}) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 如果需要考虑面板，则减去面板宽度 (仅限桌面端)
    if (withPanels && isDesktop) {
      double panelWidth = getSidePanelWidth(context);
      double deduction = 0;
      // 检查面板是否真的可见 (基于传入的状态)
      if (leftPanelVisible) deduction += panelWidth;
      if (rightPanelVisible) deduction += panelWidth;
      // 确保可用宽度不小于0
      return max(0, screenWidth - deduction);
    }
    // 否则返回完整屏幕宽度
    return screenWidth;
  }

  // 计算一行能容纳的卡片数量
  static int calculateGameCardsInGameListPerRow(BuildContext context,
      {bool withPanels = false,
      // 当 directAvailableWidth 为 null 时，此参数才用于 getAvailableContentWidth
      bool leftPanelVisible = false,
      bool rightPanelVisible = false,
      bool isCompact = false,
      double? directAvailableWidth}) {
    final double availableWidth = directAvailableWidth ??
        getAvailableContentWidth(context,
            withPanels: withPanels,
            leftPanelVisible: leftPanelVisible,
            rightPanelVisible: rightPanelVisible);

    final double horizontalPadding = 16.0;
    final double crossAxisSpacing = 8.0;
    final double effectiveWidth = availableWidth - horizontalPadding;

    if (effectiveWidth <= 0) return 1;

    double targetCardWidth;
    // targetCardWidth 的选择现在只看 availableWidth
    if (availableWidth < 400) {
      isCompact ? targetCardWidth = 120 : targetCardWidth = 150;
    } else if (availableWidth < 600) {
      isCompact ? targetCardWidth = 130 : targetCardWidth = 160;
    } else if (availableWidth < 900) {
      isCompact ? targetCardWidth = 140 : targetCardWidth = 165;
    } else if (availableWidth < 1200) {
      isCompact ? targetCardWidth = 150 : targetCardWidth = 170;
    } else {
      isCompact ? targetCardWidth = 160 : targetCardWidth = 190;
    }

    int cardsPerRow = ((effectiveWidth + crossAxisSpacing) /
            (targetCardWidth + crossAxisSpacing))
        .floor();
    return max(1, cardsPerRow);
  }

  static double calculateGameCardHeight(
      BuildContext context, bool showTags, bool isCompact) {
    final imageHeight = isCompact ? 140.0 : 160.0;
    final titleHeight = isCompact ? 22.0 : 24.0;
    final summaryHeight = isAndroidPortrait(context)
        ? (isCompact ? 18.0 : 20.0)
        : (isCompact ? 36.0 : 40.0);
    final tagsHeight = showTags ? (isCompact ? 24.0 : 28.0) : 0.0;
    final statsHeight = isCompact ? 24.0 : 28.0;
    final padding = isCompact ? 16.0 : 20.0;
    return imageHeight +
        titleHeight +
        summaryHeight +
        tagsHeight +
        statsHeight +
        padding;
  }

  // 修正：当 directAvailableWidth 提供时，minRatio/maxRatio 的选择逻辑更新
  static double calculateGameCardRatio(BuildContext context,
      {bool withPanels =
          false, // 当 direct* 为 null 时，此参数用于 getAvailableContentWidth 和 ratio 约束
      bool leftPanelVisible = false,
      bool rightPanelVisible = false,
      bool showTags = true,
      double? directAvailableWidth,
      int? directCardsPerRow}) {
    final availableWidth = directAvailableWidth ??
        getAvailableContentWidth(context,
            withPanels: withPanels,
            leftPanelVisible: leftPanelVisible,
            rightPanelVisible: rightPanelVisible);

    final cardsPerRow = directCardsPerRow ??
        calculateGameCardsInGameListPerRow(context,
            directAvailableWidth: availableWidth, // 传递修正后的 availableWidth
            // 下面这些参数在 calculateGameCardsInGameListScreenPerRow 内部
            // 当 directAvailableWidth 有值时，withPanels不再直接影响targetCardWidth的选取逻辑
            withPanels: withPanels, // 仍然传递，以防旧的依赖
            leftPanelVisible: leftPanelVisible,
            rightPanelVisible: rightPanelVisible);
    if (cardsPerRow <= 0) return 1.0;

    final horizontalPadding = 16.0;
    final crossAxisSpacing = 8.0;
    final actualCardWidth = (availableWidth -
            horizontalPadding -
            (crossAxisSpacing * (cardsPerRow - 1))) /
        cardsPerRow;
    if (actualCardWidth <= 0) return 1.0;

    final isCompact = (cardsPerRow > 3) || (actualCardWidth < 180);
    final cardHeight = calculateGameCardHeight(context, showTags, isCompact);
    if (cardHeight <= 0) return 1.0;

    double ratio = actualCardWidth / cardHeight;
    double minRatio, maxRatio;

    if (directAvailableWidth != null) {
      // 当可用宽度是直接指定时 (LayoutBuilder场景)
      // minRatio/maxRatio 基于 cardsPerRow (它是由 directAvailableWidth 决定的)
      if (cardsPerRow == 1) {
        // 单列显示，允许卡片更高（ratio更小）
        minRatio = 0.60; // 例如，接近 2:3 或 3:4 的高卡片
        maxRatio = 0.85; // 不要太扁
      } else if (cardsPerRow == 2) {
        // 双列
        minRatio = 0.65;
        maxRatio = 0.90;
      } else {
        // 三列及以上，可以更接近方形或略宽
        minRatio = 0.70;
        maxRatio = 0.95; // 允许更宽一点
      }
    } else {
      // 回退到旧的、基于固定面板假设的 withPanels 判断逻辑
      if (withPanels) {
        // 假设是固定宽度面板挤压
        minRatio = 0.70;
        maxRatio = 0.90;
      } else {
        // 无面板或移动端
        minRatio = 0.75;
        maxRatio = 0.95;
      }
    }

    // Android 竖屏的特殊处理可以叠加或调整上述值
    if (isAndroidPortrait(context)) {
      // 确保在安卓竖屏下，卡片不会过扁
      // 如果上面的计算得到的 maxRatio 比较大，这里可以强制压低
      maxRatio = min(maxRatio, 0.85); // 例如，安卓竖屏最多是这个比例
      // 同时，也可能需要调整 minRatio，防止过高
      minRatio = max(minRatio, 0.60); // 例如，安卓竖屏最少是这个比例
    }
    // print('CalculateGameCardRatio: availableWidth=$availableWidth, cardsPerRow=$cardsPerRow, actualCardWidth=$actualCardWidth, cardHeight=$cardHeight, initialRatio=$ratio, finalRatio=${ratio.clamp(minRatio, maxRatio)}, directProvided: ${directAvailableWidth != null}');
    return ratio.clamp(minRatio, maxRatio);
  }

  // 包装方法：为热门/最新列表计算卡片比例 (无面板)
  static double calculateSimpleGameCardRatio(BuildContext context,
      {bool showTags = true}) {
    // 这个方法调用时，directAvailableWidth 和 directCardsPerRow 都是 null
    // 所以会走 calculateGameCardRatio 内部的 else (基于 withPanels=false 的旧逻辑)
    return calculateGameCardRatio(context,
        withPanels: false, showTags: showTags);
  }

  // 包装方法：为带固定宽度面板的游戏列表计算卡片比例
  static double calculateGameListCardRatio(
      BuildContext context, bool leftPanelVisible, bool rightPanelVisible,
      {bool showTags = true}) {
    // 这个方法调用时，directAvailableWidth 和 directCardsPerRow 都是 null
    // 所以会走 calculateGameCardRatio 内部的 else (基于 withPanels=true 的旧逻辑)
    return calculateGameCardRatio(context,
        withPanels: true,
        leftPanelVisible: leftPanelVisible,
        rightPanelVisible: rightPanelVisible,
        showTags: showTags);
  }

  static int calculatePostCardsPerRow(BuildContext context) {
    final availableWidth = getAvailableContentWidth(context);
    final horizontalPadding = 16.0; // GridView 左右的总内边距
    final crossAxisSpacing = 16.0; // 卡片间的水平间距

    final effectiveWidth = availableWidth - horizontalPadding;
    if (effectiveWidth <= 0) return 1;

    double targetCardWidth;
    if (availableWidth < 600) {
      targetCardWidth = 200; // 窄屏下帖子卡片可以稍宽
    } else if (availableWidth < 900) {
      targetCardWidth = 250;
    } else if (availableWidth < 1200) {
      targetCardWidth = 280;
    } else {
      targetCardWidth = 300; // 大屏下帖子卡片宽度
    }

    int cardsPerRow = ((effectiveWidth + crossAxisSpacing) /
            (targetCardWidth + crossAxisSpacing))
        .floor();

    return max(1, cardsPerRow);
  }

  // 原有的帖子卡片比例计算
  static double calculatePostCardRatio(BuildContext context) {
    final availableWidth = getAvailableContentWidth(context);
    final horizontalPadding = 16.0;
    final crossAxisSpacing = 16.0;

    final cardsPerRow = calculatePostCardsPerRow(context);
    if (cardsPerRow <= 0) return 1.0;

    final actualCardWidth = (availableWidth -
            horizontalPadding -
            (crossAxisSpacing * (cardsPerRow - 1))) /
        cardsPerRow;
    if (actualCardWidth <= 0) return 1.0;

    // 重新评估 BasePostCard 的高度构成
    // 根据 BasePostCard.dart 代码
    // Padding: 12 + 12 + 8 (顶部标题+标签下方+底部)
    // 标题: 固定高度 (约2行)
    // 内容: 弹性部分，但通常显示2行，这里给一个估算值
    // 标签行: 固定高度 (32) 或者0
    // 底部信息栏: 固定高度 (36)
    // StylishPopupMenuButton: 会占据一定高度

    // 假设 BasePostCard 内部的 Padding (vertical): 12 (top) + 8 (bottom for Row) = 20
    // 底部 Container 的 vertical padding: 8 + 8 = 16
    // 总垂直间距 ≈ 20 + 16 = 36

    // 标题高度（最多2行）
    final double titleHeight =
        isAndroid && isPortrait(context) ? 36.0 : 40.0; // 提高以容纳2行文本
    // 标签行高度
    final double tagsHeight = 32.0;
    // 底部统计行高度
    final double infoRowHeight = 40.0; // UserInfoBadge 和 PostStatisticsRow 高度
    // 额外的顶部/底部 padding, Column间距等估算
    final double verticalSpacing = 24.0; // 综合估算内部Column的padding和间距

    // 核心问题是内容部分（Expanded）会占据剩余空间，但它不能无限制地压缩
    // 如果没有Expanded，它会是 Text 自身的高度
    // 这里我们强制给内容一个最小高度，以防止溢出
    final double minContentHeight =
        isAndroid && isPortrait(context) ? 40.0 : 50.0; // 至少2行文本高度

    // 计算总卡片高度，这个估算要更保守，宁高勿低
    final double estimatedCardHeight = titleHeight +
        minContentHeight +
        tagsHeight +
        infoRowHeight +
        verticalSpacing;

    double ratio = actualCardWidth / estimatedCardHeight;

    // 再次调整钳制范围，确保卡片不会过“扁”（过高），允许其更“方”或略“宽”
    // 这个范围需要根据实际内容和UI效果反复调试
    // 报错信息显示 overflowed by 63 pixels，说明高度严重不足
    // 因此，需要显著减小 ratio 的上限，让卡片变“高”
    ratio = ratio.clamp(0.85, 1.2); // 调整到更“方”的比例，让高度更充足

    // Android 竖屏特殊处理 (屏幕窄，易显长)
    if (isAndroid && isPortrait(context)) {
      // 竖屏下卡片更窄，对应实际高度会更高，所以比例会更小
      // 允许它更“高”一点，降低上限
      ratio = ratio.clamp(0.75, 1.0); // 调整以允许更高的卡片
    }

    return ratio;
  }
}

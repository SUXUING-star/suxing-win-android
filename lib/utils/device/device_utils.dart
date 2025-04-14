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
  static int calculateCardsPerRow(BuildContext context, {bool withPanels = false, bool leftPanelVisible = false, bool rightPanelVisible = false}) {
    // 1. 获取实际可用的内容区域宽度
    final availableWidth = getAvailableContentWidth(
        context,
        withPanels: withPanels,
        leftPanelVisible: leftPanelVisible,
        rightPanelVisible: rightPanelVisible
    );

    // 2. 定义布局常量
    final horizontalPadding = 16.0; // GridView 左右的总内边距 (8+8)
    final crossAxisSpacing = 8.0;   // 卡片间的水平间距

    // 3. 计算真正用于放置卡片的有效宽度
    final effectiveWidth = availableWidth - horizontalPadding;
    if (effectiveWidth <= 0) return 1; // 保证至少返回1

    // 4. 根据屏幕宽度动态调整目标卡片宽度 (决定一行放多少个)
    double targetCardWidth;
    // 这些阈值基于 *可用宽度* 而不是屏幕总宽度
    if (availableWidth < 600) {
      targetCardWidth = 160; // 极窄屏幕
    } else if (availableWidth < 900) {
      targetCardWidth = 180; // 中小屏幕
    } else if (availableWidth < 1200) {
      targetCardWidth = 200; // 中等屏幕
    } else {
      targetCardWidth = 220; // 大屏幕
    }

    // 5. 计算理论上可以放下的卡片数量
    // 公式: (总宽度 + 单个间距) / (单个卡片宽度 + 单个间距) -> 向下取整
    int cardsPerRow = ((effectiveWidth + crossAxisSpacing) / (targetCardWidth + crossAxisSpacing)).floor();

    // 6. 保证至少有1张卡片
    return max(1, cardsPerRow);
  }

  // 计算卡片高度 (估算值)
  static double calculateCardHeight(BuildContext context, bool showTags, bool isCompact) {
    // 基础组件高度估算 (需要根据你的 BaseGameCard 内部布局调整)
    final imageHeight = isCompact ? 140.0 : 160.0;   // 图片高度
    final titleHeight = isCompact ? 22.0 : 24.0;   // 标题高度 (单行)
    // 摘要高度，假设安卓竖屏显示1行，其他情况2行
    final summaryHeight = isAndroidPortrait(context) ?
    (isCompact ? 18.0 : 20.0) : (isCompact ? 36.0 : 40.0); // 摘要高度
    final tagsHeight = showTags ? (isCompact ? 24.0 : 28.0) : 0.0; // 标签行高度
    final statsHeight = isCompact ? 24.0 : 28.0;   // 统计信息行高度
    final padding = isCompact ? 16.0 : 20.0;       // 卡片内部垂直总间距/边距

    // 总高度
    return imageHeight + titleHeight + summaryHeight + tagsHeight + statsHeight + padding;
  }

  // 核心：计算卡片宽高比
  static double calculateCardRatio(BuildContext context, {
    bool withPanels = false,
    bool leftPanelVisible = false,
    bool rightPanelVisible = false,
    bool showTags = true
  }) {
    // 1. 计算一行应有多少卡片
    final cardsPerRow = calculateCardsPerRow(
        context,
        withPanels: withPanels,
        leftPanelVisible: leftPanelVisible,
        rightPanelVisible: rightPanelVisible
    );
    if (cardsPerRow <= 0) return 1.0; // 安全退出

    // 2. 获取可用内容宽度
    final availableWidth = getAvailableContentWidth(
        context,
        withPanels: withPanels,
        leftPanelVisible: leftPanelVisible,
        rightPanelVisible: rightPanelVisible
    );

    // 3. 计算实际分配给每个卡片的宽度
    final horizontalPadding = 16.0; // GridView 左右总 padding
    final crossAxisSpacing = 8.0;   // 卡片间距
    // 公式: (总可用宽度 - 总内边距 - 总间距) / 卡片数
    final actualCardWidth = (availableWidth - horizontalPadding - (crossAxisSpacing * (cardsPerRow - 1))) / cardsPerRow;
    if (actualCardWidth <= 0) return 1.0; // 安全退出

    // 4. 确定卡片是否应使用紧凑模式
    // 当一行卡片数较多(>3)，或者单个卡片宽度较窄时，使用紧凑模式
    final isCompact = (cardsPerRow > 3) || (actualCardWidth < 180);

    // 5. 计算卡片所需高度
    final cardHeight = calculateCardHeight(context, showTags, isCompact);
    if (cardHeight <= 0) return 1.0; // 安全退出

    // 6. 计算原始宽高比 (宽 / 高)
    double ratio = actualCardWidth / cardHeight;

    // 7. [关键] 限制宽高比在合理范围内 (避免过宽或过窄)
    //    这一步是为了视觉效果，防止比例极端化
    //    ==== 这里是需要调整的地方 ====
    double minRatio, maxRatio;

    if (withPanels && isDesktop) {
      // 有面板时卡片较窄，天然 ratio 可能偏低，但也别太低
      minRatio = 0.70;  // *** 显著提高有面板时的最小比例 ***
      maxRatio = 0.90;  // 允许更接近方形
    } else {
      // 无面板时卡片较宽，天然 ratio 可能偏高，但也别太低（过扁也不行）
      // 关键是防止它变得过低 (太长)
      minRatio = 0.75;  // *** 显著提高无面板时的最小比例 ***
      maxRatio = 0.95;  // 允许接近方形，甚至略宽
    }

    // Android 竖屏特殊处理 (屏幕窄，易显长)
    if (isAndroidPortrait(context)) {
      minRatio = 0.70; // *** 提高 Android 竖屏最小比例 ***
      maxRatio = 0.85; // 限制最大比例，防止过扁
    }

    // 打印调试信息
    // print('屏幕宽度: ${MediaQuery.of(context).size.width}, '
    //     '有效宽度: $availableWidth, '
    //     '卡片数: $cardsPerRow, '
    //     '卡片宽度: $actualCardWidth, '
    //     '卡片高度: $cardHeight, '
    //     '原始比例: $ratio, '
    //     '约束: [$minRatio, $maxRatio], '
    //     '有面板: $withPanels, '
    //     '紧凑: $isCompact');

    // 返回约束后的比例
    return ratio.clamp(minRatio, maxRatio);
  }

  // 包装方法：为热门/最新列表计算卡片比例 (无面板)
  static double calculateSimpleCardRatio(BuildContext context, {bool showTags = true}) {
    return calculateCardRatio(
        context,
        withPanels: false, // 明确无面板
        showTags: showTags
    );
  }


  // 包装方法：为带面板的游戏列表计算卡片比例
  static double calculateGameListCardRatio(BuildContext context, bool leftPanelVisible, bool rightPanelVisible, {bool showTags = true}) {
    return calculateCardRatio(
        context,
        withPanels: true, // 明确有面板
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
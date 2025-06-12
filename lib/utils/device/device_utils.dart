// lib/utils/device/device_utils.dart

/// 该文件定义了 DeviceUtils 工具类，提供设备相关属性和尺寸计算方法。
/// 该类用于判断设备类型、屏幕方向以及计算 UI 元素的尺寸。
library;

import 'dart:math'; // 导入数学函数，如 sqrt
import 'dart:io' show Platform; // 导入 Platform 类，用于获取平台信息
import 'package:flutter/material.dart'; // 导入 Flutter UI 组件和 MediaQuery
import 'package:flutter/foundation.dart'
    show kIsWeb; // 导入 kIsWeb，用于判断是否是 Web 平台

/// `DeviceUtils` 类：提供设备相关的实用方法。
///
/// 该类包含判断设备类型、屏幕方向、屏幕尺寸等级以及计算 UI 元素尺寸的方法。
class DeviceUtils {
  /// 判断当前是否运行在 Web 平台。
  static bool get isWeb => kIsWeb;

  /// 判断设备是否为平板。
  ///
  /// [context]：Build 上下文。
  /// 根据屏幕对角线长度判断是否为平板。
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size; // 获取屏幕尺寸
    final diagonal =
        sqrt(size.width * size.width + size.height * size.height); // 计算屏幕对角线长度
    return diagonal > 1100; // 对角线长度大于特定值时判定为平板
  }

  /// 判断当前是否运行在 Android 平台。
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// 判断当前是否运行在 iOS 平台。
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// 判断当前是否运行在 Windows 平台。
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// 判断当前是否运行在桌面平台（Windows, Linux, macOS）。
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// 判断当前屏幕是否为横屏。
  ///
  /// [context]：Build 上下文。
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation ==
        Orientation.landscape; // 获取屏幕方向
  }

  /// 判断当前屏幕是否为竖屏。
  ///
  /// [context]：Build 上下文。
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait; // 获取屏幕方向
  }

  /// 判断当前屏幕是否为大屏幕。
  ///
  /// [context]：Build 上下文。
  /// 根据屏幕宽度判断是否为大屏幕。
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200; // 屏幕宽度大于等于特定值时判定为大屏幕
  }

  /// 返回屏幕宽度
  /// [context]：Build 上下文。
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 返回屏幕尺寸
  /// [context]：Build 上下文。
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// 判断当前屏幕是否为桌面屏幕尺寸。
  ///
  /// [context]：Build 上下文。
  /// 根据屏幕宽度判断是否为桌面屏幕。
  static bool isDesktopScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900; // 屏幕宽度大于等于特定值时判定为桌面屏幕
  }

  /// 判断当前屏幕是否为桌面屏幕尺寸。
  ///
  /// [dialogContext]：Build 上下文。
  /// 根据屏幕宽度判断是否为桌面屏幕。
  static bool isDesktopInThisWidth(double screenWidth) {
    return screenWidth >= 900; // 屏幕宽度大于等于特定值时判定为桌面屏幕
  }

  /// 获取当前窗口是否为全屏状态。
  ///
  /// 该方法在桌面平台始终返回 false。
  static bool get isFullScreen {
    if (isDesktop) {
      return false;
    }
    return false;
  }

  /// 判断是否为 Android 横屏。
  ///
  /// [context]：Build 上下文。
  static bool isAndroidLandscape(BuildContext context) {
    return isAndroid && isLandscape(context); // 判断是否为 Android 且为横屏
  }

  /// 判断是否为 Android 竖屏。
  ///
  /// [context]：Build 上下文。
  static bool isAndroidPortrait(BuildContext context) {
    return isAndroid && isPortrait(context); // 判断是否为 Android 且为竖屏
  }

  // 获取基础尺寸
  /// 获取工具栏高度。
  ///
  /// [context]：Build 上下文。
  /// 根据是否为 Android 横屏调整工具栏高度。
  static double getToolbarHeight(BuildContext context) {
    return isAndroidLandscape(context)
        ? kToolbarHeight * 0.8
        : kToolbarHeight; // 返回工具栏高度
  }

  /// 获取图标尺寸。
  ///
  /// [context]：Build 上下文。
  /// 根据是否为 Android 横屏调整图标尺寸。
  static double getIconSize(BuildContext context) {
    return isAndroidLandscape(context) ? 18.0 : 20.0; // 返回图标尺寸
  }

  /// 获取内边距。
  ///
  /// [context]：Build 上下文。
  /// 根据是否为 Android 横屏调整内边距。
  static double getPadding(BuildContext context) {
    return isAndroidLandscape(context) ? 4.0 : 8.0; // 返回内边距
  }

  /// 获取侧边面板宽度。
  ///
  /// [screenWidth] 屏幕宽度
  /// 根据屏幕宽度返回不同的面板宽度。
  static double getSidePanelWidthInScreenWidth(
    double screenWidth,
  ) {
    if (screenWidth < 600) {
      return 180; // 窄屏幕面板宽度
    } else if (screenWidth < 1200) {
      return 200; // 中等屏幕面板宽度
    } else {
      return 220; // 宽屏幕面板宽度
    }
  }

  /// 获取可用内容宽度。
  ///
  /// [context]：Build 上下文。
  /// [withPanels]：是否考虑侧边面板宽度。
  /// [leftPanelVisible]：左侧面板是否可见。
  /// [rightPanelVisible]：右侧面板是否可见。
  /// 根据屏幕宽度和面板可见性计算可用内容宽度。
  static double getAvailableContentWidth(BuildContext context,
      {bool withPanels = false,
      bool leftPanelVisible = true,
      bool rightPanelVisible = true}) {
    final screenWidth = MediaQuery.of(context).size.width; // 获取屏幕宽度

    if (withPanels && isDesktop) {
      // 如果考虑面板且为桌面平台
      double panelWidth = getSidePanelWidthInScreenWidth(screenWidth); // 获取面板宽度
      double deduction = 0; // 初始化扣减值
      if (leftPanelVisible) deduction += panelWidth; // 左侧面板可见时增加扣减
      if (rightPanelVisible) deduction += panelWidth; // 右侧面板可见时增加扣减
      return max(0, screenWidth - deduction); // 返回可用宽度
    }
    return screenWidth; // 返回完整屏幕宽度
  }

  /// 计算游戏列表中每行可容纳的卡片数量。
  ///
  /// [context]：Build 上下文。
  /// [withPanels]：是否考虑侧边面板。
  /// [leftPanelVisible]：左侧面板是否可见。
  /// [rightPanelVisible]：右侧面板是否可见。
  /// [isCompact]：是否为紧凑模式。
  /// [directAvailableWidth]：直接提供的可用宽度。
  /// 根据可用宽度和卡片目标宽度计算每行卡片数量。
  static int calculateGameCardsInGameListPerRow(BuildContext context,
      {bool withPanels = false,
      bool leftPanelVisible = false,
      bool rightPanelVisible = false,
      bool isCompact = false,
      double? directAvailableWidth}) {
    final double availableWidth = directAvailableWidth ??
        getAvailableContentWidth(
          context,
          withPanels: withPanels,
          leftPanelVisible: leftPanelVisible,
          rightPanelVisible: rightPanelVisible,
        ); // 获取可用宽度

    final double horizontalPadding = 16.0; // 水平内边距
    final double crossAxisSpacing = 8.0; // 水平间距
    final double effectiveWidth = availableWidth - horizontalPadding; // 有效宽度

    if (effectiveWidth <= 0) return 1; // 有效宽度小于等于 0 时返回 1

    double targetCardWidth; // 目标卡片宽度
    if (availableWidth < 400) {
      isCompact ? targetCardWidth = 120 : targetCardWidth = 140;
    } else if (availableWidth < 600) {
      isCompact ? targetCardWidth = 130 : targetCardWidth = 150;
    } else if (availableWidth < 900) {
      isCompact ? targetCardWidth = 140 : targetCardWidth = 155;
    } else if (availableWidth < 1200) {
      isCompact ? targetCardWidth = 150 : targetCardWidth = 160;
    } else {
      isCompact ? targetCardWidth = 160 : targetCardWidth = 175;
    }

    int cardsPerRow = ((effectiveWidth + crossAxisSpacing) /
            (targetCardWidth + crossAxisSpacing))
        .floor(); // 计算每行卡片数量
    return max(1, cardsPerRow); // 返回每行卡片数量，至少为 1
  }

  /// 计算游戏卡片的高度。
  ///
  /// [context]：Build 上下文。
  /// [showTags]：是否显示标签。
  /// [isCompact]：是否为紧凑模式。
  /// 根据各项元素的高度和模式计算卡片总高度。
  static double calculateGameCardHeight(
      BuildContext context, bool showTags, bool isCompact) {
    final imageHeight = isCompact ? 140.0 : 160.0; // 图片高度
    final titleHeight = isCompact ? 22.0 : 24.0; // 标题高度
    final summaryHeight = isAndroidPortrait(context)
        ? (isCompact ? 18.0 : 20.0)
        : (isCompact ? 36.0 : 40.0); // 摘要高度
    final tagsHeight = showTags ? (isCompact ? 24.0 : 28.0) : 0.0; // 标签高度
    final statsHeight = isCompact ? 24.0 : 28.0; // 统计信息高度
    final padding = isCompact ? 16.0 : 20.0; // 内边距
    return imageHeight +
        titleHeight +
        summaryHeight +
        tagsHeight +
        statsHeight +
        padding; // 返回卡片总高度
  }

  /// 计算游戏卡片的宽高比。
  ///
  /// [context]：Build 上下文。
  /// [withPanels]：是否考虑侧边面板。
  /// [leftPanelVisible]：左侧面板是否可见。
  /// [rightPanelVisible]：右侧面板是否可见。
  /// [showTags]：是否显示标签。
  /// [directAvailableWidth]：直接提供的可用宽度。
  /// [directCardsPerRow]：直接提供的每行卡片数量。
  /// 根据可用宽度、每行卡片数量、卡片高度和平台特性计算宽高比。
  static double calculateGameCardRatio(BuildContext context,
      {bool withPanels = false,
      bool leftPanelVisible = false,
      bool rightPanelVisible = false,
      bool showTags = true,
      double? directAvailableWidth,
      int? directCardsPerRow}) {
    final availableWidth = directAvailableWidth ??
        getAvailableContentWidth(context,
            withPanels: withPanels,
            leftPanelVisible: leftPanelVisible,
            rightPanelVisible: rightPanelVisible); // 获取可用宽度

    final cardsPerRow = directCardsPerRow ??
        calculateGameCardsInGameListPerRow(context,
            directAvailableWidth: availableWidth,
            withPanels: withPanels,
            leftPanelVisible: leftPanelVisible,
            rightPanelVisible: rightPanelVisible); // 计算每行卡片数量
    if (cardsPerRow <= 0) return 1.0; // 每行卡片数量小于等于 0 时返回默认比例

    final horizontalPadding = 16.0; // 水平内边距
    final crossAxisSpacing = 8.0; // 水平间距
    final actualCardWidth = (availableWidth -
            horizontalPadding -
            (crossAxisSpacing * (cardsPerRow - 1))) /
        cardsPerRow; // 计算实际卡片宽度
    if (actualCardWidth <= 0) return 1.0; // 实际卡片宽度小于等于 0 时返回默认比例

    final isCompact = (cardsPerRow > 3) || (actualCardWidth < 180); // 判断是否为紧凑模式
    final cardHeight =
        calculateGameCardHeight(context, showTags, isCompact); // 计算卡片高度
    if (cardHeight <= 0) return 1.0; // 卡片高度小于等于 0 时返回默认比例

    double ratio = actualCardWidth / cardHeight; // 计算初始宽高比
    double minRatio, maxRatio; // 最小和最大宽高比

    if (directAvailableWidth != null) {
      // 当可用宽度直接指定时
      if (cardsPerRow == 1) {
        minRatio = 0.60;
        maxRatio = 0.85;
      } else if (cardsPerRow == 2) {
        minRatio = 0.65;
        maxRatio = 0.90;
      } else {
        minRatio = 0.70;
        maxRatio = 0.95;
      }
    } else {
      if (withPanels) {
        minRatio = 0.70;
        maxRatio = 0.90;
      } else {
        minRatio = 0.75;
        maxRatio = 0.95;
      }
    }

    if (isAndroidPortrait(context)) {
      // Android 竖屏特殊处理
      maxRatio = min(maxRatio, 0.85); // 限制最大宽高比
      minRatio = max(minRatio, 0.60); // 限制最小宽高比
    }

    final double finalRatio = ratio.clamp(minRatio, maxRatio);
    return finalRatio; // 返回钳制后的宽高比
  }

  /// 计算热门/最新游戏列表的卡片比例。
  ///
  /// [context]：Build 上下文。
  /// [showTags]：是否显示标签。
  /// 调用 `calculateGameCardRatio` 方法，不考虑侧边面板。
  static double calculateSimpleGameCardRatio(BuildContext context,
      {bool showTags = true}) {
    return calculateGameCardRatio(context,
        withPanels: false, showTags: showTags); // 调用 calculateGameCardRatio
  }

  /// 计算带固定宽度面板的游戏列表卡片比例。
  ///
  /// [context]：Build 上下文。
  /// [leftPanelVisible]：左侧面板是否可见。
  /// [rightPanelVisible]：右侧面板是否可见。
  /// [showTags]：是否显示标签。
  /// 调用 `calculateGameCardRatio` 方法，考虑侧边面板。
  static double calculateGameListCardRatio(
    BuildContext context, {
    bool leftPanelVisible = false,
    bool rightPanelVisible = false,
    bool showTags = true,
    double? directAvailableWidth,
  }) {
    return calculateGameCardRatio(context,
        withPanels: true,
        directAvailableWidth: directAvailableWidth,
        leftPanelVisible: leftPanelVisible,
        rightPanelVisible: rightPanelVisible,
        showTags: showTags); // 调用 calculateGameCardRatio
  }

  /// 计算每行可容纳的帖子卡片数量。
  ///
  /// [context]：Build 上下文。
  /// 根据可用宽度和卡片目标宽度计算每行卡片数量。
  static int calculatePostCardsPerRow(
    BuildContext context, {
    bool withPanels = false,
    bool leftPanelVisible = true,
    bool rightPanelVisible = true,
    double? directAvailableWidth,
  }) {
    final availableWidth = directAvailableWidth ??
        getAvailableContentWidth(
          context,
          withPanels: withPanels,
          leftPanelVisible: leftPanelVisible,
          rightPanelVisible: rightPanelVisible,
        ); // 获取可用宽度
    final horizontalPadding = 16.0; // GridView 左右的总内边距
    final crossAxisSpacing = 16.0; // 卡片间的水平间距

    final effectiveWidth = availableWidth - horizontalPadding; // 有效宽度
    if (effectiveWidth <= 0) return 1; // 有效宽度小于等于 0 时返回 1

    double targetCardWidth; // 目标卡片宽度
    if (availableWidth < 600) {
      targetCardWidth = 200;
    } else if (availableWidth < 900) {
      targetCardWidth = 250;
    } else if (availableWidth < 1200) {
      targetCardWidth = 280;
    } else {
      targetCardWidth = 300;
    }

    int cardsPerRow = ((effectiveWidth + crossAxisSpacing) /
            (targetCardWidth + crossAxisSpacing))
        .floor(); // 计算每行卡片数量

    return max(1, cardsPerRow); // 返回每行卡片数量，至少为 1
  }

  /// 计算帖子卡片的高度。
  ///
  /// 该方法通过累加卡片内各可见部分的精确高度来计算总高度。
  /// 为了保持布局计算的统一性，标题区域的底部留白始终按有标签的情况处理。
  static double calculatePostCardHeight(
    BuildContext context, {
    required int? contentMaxLines,
    required bool isDesktopLayout,
    required double screenWidth,
  }) {
    // 1. 标题区域高度
    // 标题区域的底部留白始终为最大值(28.0)，以容纳可能存在的悬浮标签。
    // 这确保了无论有无标签，外部计算的高度都是一致的。
    const double titleTopPadding = 12.0;
    const double titleBottomPadding = 28.0; // 固定为最大值
    final double titleFontSize = isDesktopLayout ? 16 : 14;
    final double titleLineHeight = 1.2;
    const double titleMaxLines = 2;
    final double titleHeight =
        (titleFontSize * titleLineHeight * titleMaxLines) +
            titleTopPadding +
            titleBottomPadding;

    // 2. 内容区域高度
    double contentHeight = 0;
    if (contentMaxLines != null && contentMaxLines > 0) {
      const double contentVerticalPadding = 8.0 + 12.0;
      final double contentFontSize = isDesktopLayout ? 14 : 13;
      final double contentLineHeight = 1.5;
      contentHeight = (contentFontSize * contentLineHeight * contentMaxLines) +
          contentVerticalPadding;
    }

    // 3. 底部信息栏高度
    const double bottomBarVerticalPadding = 8.0 * 2;
    const double thresholdWidth = 400.0;
    final bool isBottomBarSingleLine = screenWidth >= thresholdWidth;

    final double userInfoBadgeHeight = isDesktopLayout ? 24.0 : 22.0;
    final double statsRowHeight = isDesktopLayout ? 20.0 : 18.0;

    double bottomBarHeight;
    if (isBottomBarSingleLine) {
      bottomBarHeight =
          max(userInfoBadgeHeight, statsRowHeight) + bottomBarVerticalPadding;
    } else {
      const double spacing = 6.0;
      bottomBarHeight = userInfoBadgeHeight +
          statsRowHeight +
          spacing +
          bottomBarVerticalPadding;
    }

    // 最终高度为各部分之和。
    return titleHeight + contentHeight + bottomBarHeight;
  }

  /// 计算帖子卡片的宽高比 (childAspectRatio)。
  ///
  /// 该方法不再需要关心帖子是否有标签，简化了调用。
  static double calculatePostCardRatio(
    BuildContext context, {
    int contentMaxLines = 2,
    bool withPanel = false,
    bool showLeftPanel = false,
    bool showRightPanel = false,
    double? directAvailableWidth,
  }) {
    final availableWidth = directAvailableWidth ??
        getAvailableContentWidth(
          context,
          withPanels: withPanel,
          leftPanelVisible: showLeftPanel,
          rightPanelVisible: showRightPanel,
        );
    final isDesktopLayout = isDesktopScreen(context);

    final horizontalPadding = 16.0;
    final crossAxisSpacing = 16.0;

    final cardsPerRow = calculatePostCardsPerRow(
      context,
      directAvailableWidth: availableWidth,
      withPanels: withPanel,
      leftPanelVisible: showLeftPanel,
      rightPanelVisible: showRightPanel,
    );
    if (cardsPerRow <= 0) return 1.0;

    final actualCardWidth = (availableWidth -
            horizontalPadding -
            (crossAxisSpacing * (cardsPerRow - 1))) /
        cardsPerRow;
    if (actualCardWidth <= 0) return 1.0;

    final double cardHeight = calculatePostCardHeight(
      context,
      contentMaxLines: contentMaxLines,
      isDesktopLayout: isDesktopLayout,
      screenWidth: actualCardWidth,
    );

    if (cardHeight <= 0) return 1.0;

    final double ratio = actualCardWidth / cardHeight;

    return ratio.clamp(0.7, 2.0);
  }
}

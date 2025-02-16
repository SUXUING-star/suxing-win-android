// lib/utils/device_utils.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DeviceUtils {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

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
  static double calculateCardRatio(BuildContext context) {
    // Get the available width for a single card
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 16.0; // Total padding from GridView (8.0 * 2)
    final crossAxisSpacing = 8.0;

    // Calculate how many cards can fit in a row
    final maxCardWidth = 250.0; // From GridView maxCrossAxisExtent
    final cardsPerRow = (screenWidth / (maxCardWidth + crossAxisSpacing)).floor();
    final actualCardWidth = (screenWidth - horizontalPadding - (crossAxisSpacing * (cardsPerRow - 1))) / cardsPerRow;

    // Calculate required height for the card with more generous spacing
    final imageHeight = 160.0; // Fixed image height from GameCard
    final contentPadding = 24.0; // Increased from 16.0 to 24.0
    final titleHeight = isAndroid && isPortrait(context) ? 24.0 : 28.0; // Increased height for title
    final summaryHeight = isAndroid && isPortrait(context) ? 40.0 : 44.0; // Increased height for summary
    final statsHeight = 32.0; // Increased from 24.0 to 32.0
    final additionalSpacing = 16.0; // Extra spacing for better visual appearance

    final minCardHeight = imageHeight + contentPadding + titleHeight + summaryHeight + statsHeight + additionalSpacing;

    // Add a scaling factor to make cards slightly taller
    final scalingFactor = 1.2; // Makes the card 10% taller
    final adjustedCardHeight = minCardHeight * scalingFactor;

    // Calculate and return the aspect ratio
    double ratio = actualCardWidth / adjustedCardHeight;

    // Apply minimum and maximum constraints
    ratio = ratio.clamp(0.65, 0.8);

    // For Android portrait mode, we want an even smaller ratio
    if (isAndroid && isPortrait(context)) {
      ratio = ratio.clamp(0.60, 0.65);
    }

    return ratio;
  }
}
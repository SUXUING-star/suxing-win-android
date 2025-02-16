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
}
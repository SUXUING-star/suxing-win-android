// lib/providers/device/device_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';

enum DeviceType {
  mobile,
  tablet,
  desktop
}

enum OrientationType {
  portrait,
  landscape
}

class DeviceProvider with ChangeNotifier {
  late DeviceType _deviceType;
  late OrientationType _orientation;
  late Size _screenSize;

  DeviceType get deviceType => _deviceType;
  OrientationType get orientation => _orientation;
  Size get screenSize => _screenSize;

  // 基础平台判断
  bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isMobile => isAndroid || isIOS;
  bool get isWeb => kIsWeb;

  // 设备类型判断
  bool get isTablet => _deviceType == DeviceType.tablet;
  bool get isPhone => _deviceType == DeviceType.mobile;

  // 屏幕方向判断
  bool get isPortrait => _orientation == OrientationType.portrait;
  bool get isLandscape => _orientation == OrientationType.landscape;

  // 组合判断（用于常见布局场景）
  bool get isAndroidLandscape => isAndroid && isLandscape;
  bool get isAndroidPortrait => isAndroid && isPortrait;
  bool get isMobileLandscape => isMobile && isLandscape;
  bool get isMobilePortrait => isMobile && isPortrait;

  // 布局相关的便捷值
  double get topPadding => isAndroidLandscape ? 4.0 : 8.0;
  double get bottomPadding => isAndroidLandscape ? 4.0 : 8.0;
  double get iconSize => isAndroidLandscape ? 20.0 : 24.0;
  double get smallIconSize => isAndroidLandscape ? 18.0 : 20.0;
  double get fontSize => isAndroidLandscape ? 12.0 : 14.0;
  double get smallFontSize => isAndroidLandscape ? 10.0 : 12.0;
  double get logoSize => isAndroidLandscape ? 36.0 : 48.0;
  double get appBarHeight => isAndroidLandscape ? kToolbarHeight * 0.8 : kToolbarHeight;
  double get searchBarHeight => isAndroidLandscape ? 32.0 : 40.0;
  double get avatarRadius => isAndroidLandscape ? 12.0 : 14.0;

  DeviceProvider() {
    _init();
  }

  void _init() {
    if (isDesktop) {
      _deviceType = DeviceType.desktop;
    } else {
      _deviceType = _getDeviceType();
    }

    _updateOrientation();
    WidgetsBinding.instance.addObserver(_OrientationObserver(this));
  }

  DeviceType _getDeviceType() {
    final data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    _screenSize = data.size;

    final diagonal =
    sqrt((_screenSize.width * _screenSize.width) +
        (_screenSize.height * _screenSize.height));

    return diagonal > 600 ? DeviceType.tablet : DeviceType.mobile;
  }

  void _updateOrientation() {
    final data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    _screenSize = data.size;
    _orientation = _screenSize.width > _screenSize.height
        ? OrientationType.landscape
        : OrientationType.portrait;
    notifyListeners();
  }
}

class _OrientationObserver extends WidgetsBindingObserver {
  final DeviceProvider provider;

  _OrientationObserver(this.provider);

  @override
  void didChangeMetrics() {
    provider._updateOrientation();
  }
}
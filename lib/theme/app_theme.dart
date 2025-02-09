// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // 定义字体家族名称
  static const String primaryFont = 'PingFang';  // 或其他你想使用的字体
  static const String fallbackFont = 'Microsoft YaHei';  // 后备字体

  // 获取主题数据
  static ThemeData get lightTheme {
    return ThemeData(
      // 设置默认字体
      fontFamily: primaryFont,

      // 配置文字主题
      textTheme: const TextTheme(
        // 标题样式
        displayLarge: TextStyle(
          fontFamily: primaryFont,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          fontFamily: primaryFont,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          fontFamily: primaryFont,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),

        // 正文样式
        bodyLarge: TextStyle(
          fontFamily: primaryFont,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          fontFamily: primaryFont,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodySmall: TextStyle(
          fontFamily: primaryFont,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),

      // 中文数字字体修正
      typography: Typography.material2021(
        platform: TargetPlatform.android,
        // 确保中文数字正确显示
        black: Typography.blackMountainView.copyWith(
          bodyLarge: const TextStyle(fontFamily: primaryFont),
          bodyMedium: const TextStyle(fontFamily: primaryFont),
          bodySmall: const TextStyle(fontFamily: primaryFont),
        ),
        white: Typography.whiteMountainView.copyWith(
          bodyLarge: const TextStyle(fontFamily: primaryFont),
          bodyMedium: const TextStyle(fontFamily: primaryFont),
          bodySmall: const TextStyle(fontFamily: primaryFont),
        ),
      ),
    );
  }
}
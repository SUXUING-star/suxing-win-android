// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'dart:io';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  void _loadThemeMode() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // 获取平台相关的字体配置
  TextTheme _getPlatformTextTheme(TextTheme baseTheme) {
    // 根据平台选择默认字体
    final String defaultFontFamily = Platform.isWindows ? 'Microsoft YaHei' : 'Roboto';
    final List<String> fontFallback = ['Microsoft YaHei', 'SimHei'];

    // 在原有样式基础上只修改字体相关属性
    return baseTheme.copyWith(
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
    );
  }

  // 亮色主题
  ThemeData get lightTheme {
    final baseTheme = ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.transparent,
    );

    return baseTheme.copyWith(
      textTheme: _getPlatformTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // 暗色主题
  ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();

    return baseTheme.copyWith(
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _getPlatformTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF1F1F1F),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
// lib/providers/theme/theme_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/font/font_config.dart';


/// 管理应用的主题，并提供主题变更的数据流。
class ThemeProvider {
  /// 初始主题模式。
  static const _initialThemeMode = ThemeMode.system;

  /// 当前的主题模式。
  /// 用于为新的流监听者提供初始值。
  ThemeMode _currentThemeMode = _initialThemeMode;

  /// 用于广播主题模式变更的流控制器。
  final _themeController = StreamController<ThemeMode>.broadcast();

  ThemeProvider() {
    _loadThemeMode();
  }

  /// 对外暴露的 [ThemeMode] 变更流，供UI组件监听。
  Stream<ThemeMode> get themeModeStream => _themeController.stream;

  /// 同步获取当前 [ThemeMode] 的方法，方便提供初始数据。
  ThemeMode get currentThemeMode => _currentThemeMode;

  /// 设置新的主题模式，并通过流通知所有监听者。
  void setThemeMode(ThemeMode mode) {
    if (mode == _currentThemeMode) return;

    _currentThemeMode = mode;
    _themeController.add(_currentThemeMode);
  }

  /// 关闭流控制器以防止内存泄漏。
  ///
  /// 当 Provider 不再需要时应调用此方法。
  void dispose() {
    _themeController.close();
  }

  /// 加载主题模式。
  ///
  /// 实际应用中，这里应从持久化存储（如 SharedPreferences）加载主题。
  void _loadThemeMode() {
    // 此处仅设置初始值并推送到流中。
    _themeController.add(_initialThemeMode);
  }

  // --- 主题数据定义 ---

  /// 应用的亮色主题配置。
  ThemeData get lightTheme {
    final baseTheme = ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue.shade300,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: FontConfig.defaultFontFamily,
      cardColor: Colors.white,
    );

    return baseTheme.copyWith(
      textTheme: _getPlatformTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontFamily: FontConfig.defaultFontFamily,
          fontFamilyFallback: FontConfig.fontFallback,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      canvasColor: Colors.white,
      cardTheme: CardTheme(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontFamilyFallback: FontConfig.fontFallback,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontFamilyFallback: FontConfig.fontFallback,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontFamilyFallback: FontConfig.fontFallback,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        errorStyle: TextStyle(
          color: Colors.red[700],
          fontSize: 12.0,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14.0,
          fontWeight: FontWeight.w300,
        ),
        floatingLabelStyle: TextStyle(
          color: Colors.blue,
          fontSize: 12.0,
        ),
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontSize: 14.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
        ),
      ),
    );
  }

  /// 应用的暗色主题配置。
  ThemeData get darkTheme {
    final baseTheme = ThemeData.dark().copyWith();

    return baseTheme.copyWith(
      primaryColor: Colors.white,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _getPlatformTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: const Color(0xFF1F1F1F),
        titleTextStyle: TextStyle(
          fontFamily: FontConfig.defaultFontFamily,
          fontFamilyFallback: FontConfig.fontFallback,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      canvasColor: Colors.white,
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontFamilyFallback: FontConfig.fontFallback,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontFamilyFallback: FontConfig.fontFallback,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: TextStyle(
            fontFamily: FontConfig.defaultFontFamily,
            fontFamilyFallback: FontConfig.fontFallback,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontSize: 14.0,
        ),
        errorStyle: TextStyle(
          color: Colors.red[700],
          fontSize: 12.0,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14.0,
          fontWeight: FontWeight.w300,
        ),
        floatingLabelStyle: TextStyle(
          color: Colors.blue,
          fontSize: 12.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
        ),
      ),
    );
  }

  /// 将平台特定的字体配置应用到给定的 [TextTheme]。
  TextTheme _getPlatformTextTheme(TextTheme baseTheme) {
    final String defaultFontFamily = FontConfig.defaultFontFamily;
    final List<String> fontFallback = FontConfig.fontFallback;

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
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontFamily: defaultFontFamily,
        fontFamilyFallback: fontFallback,
      ),
    );
  }
}
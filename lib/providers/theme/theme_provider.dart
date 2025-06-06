// lib/providers/theme/theme_provider.dart
import 'package:flutter/material.dart';
import '../../utils/font/font_config.dart'; // 引入 FontConfig

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
    // 使用 FontConfig 中定义的字体配置
    final String defaultFontFamily = FontConfig.defaultFontFamily;
    final List<String> fontFallback = FontConfig.fontFallback;

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
      // 添加更多文本样式，确保所有组件都使用正确的字体
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

  // 亮色主题
  ThemeData get lightTheme {
    final baseTheme = ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue.shade300,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: FontConfig.defaultFontFamily, // 设置全局默认字体
      cardColor: Colors.white,
    );

    return baseTheme.copyWith(
      textTheme: _getPlatformTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        // 确保 AppBar 文本也使用正确的字体
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
      // 添加按钮主题，确保按钮文本使用正确字体
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
        fillColor: Colors.grey[100], // 或者 Colors.black.withOpacity(0.04)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none, // 如果用 fillColor，可以考虑无边框或极细边框
        ),
        // 错误文本样式
        errorStyle: TextStyle(
          color: Colors.red[700],
          fontSize: 12.0,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[400],     // 1. 颜色更浅，与标签和输入内容区分
          fontSize: 14.0,            // 2. 字号可以比标签略小一点 (或相同)
          fontWeight: FontWeight.w300, // 3. 字重更轻 (Light)
        ),
        floatingLabelStyle: TextStyle(
          color: Colors.blue, // 比如用主题色
          fontSize: 12.0, // 通常浮动上去后字号会小一些
          // fontWeight: FontWeight.bold,
        ),
        labelStyle: TextStyle(
          color: Colors.grey[700], // 比占位符颜色深一点
          fontSize: 14.0,
          // fontWeight: FontWeight.normal, // 默认即可
        ),
        enabledBorder: OutlineInputBorder(
          // 或者只在 enabled 时给一个细边框
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

  // 暗色主题
  ThemeData get darkTheme {
    final baseTheme = ThemeData.dark().copyWith();

    return baseTheme.copyWith(
      primaryColor: Colors.white,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _getPlatformTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF1F1F1F),
        // 确保 AppBar 文本也使用正确的字体
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
      // 添加按钮主题，确保按钮文本使用正确字体
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
        fillColor: Colors.grey[100], // 或者 Colors.black.withOpacity(0.04)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none, // 如果用 fillColor，可以考虑无边框或极细边框
        ),
        labelStyle: TextStyle(
          color: Colors.grey[700], // 比占位符颜色深一点
          fontSize: 14.0,
          // fontWeight: FontWeight.normal, // 默认即可
        ),
        // 错误文本样式
        errorStyle: TextStyle(
          color: Colors.red[700],
          fontSize: 12.0,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[400],     // 1. 颜色更浅，与标签和输入内容区分
          fontSize: 14.0,            // 2. 字号可以比标签略小一点 (或相同)
          fontWeight: FontWeight.w300, // 3. 字重更轻 (Light)
        ),
        floatingLabelStyle: TextStyle(
          color: Colors.blue, // 比如用主题色
          fontSize: 12.0, // 通常浮动上去后字号会小一些
          // fontWeight: FontWeight.bold,
        ),
        enabledBorder: OutlineInputBorder(
          // 或者只在 enabled 时给一个细边框
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
}

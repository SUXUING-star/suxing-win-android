// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  void _loadThemeMode() {
    // 简化为基础实现，移除 SharedPreferences
    _themeMode = ThemeMode.system;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // 亮色主题
  ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.transparent, // 设置为透明
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
    return ThemeData.dark().copyWith(
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.transparent, // 设置为透明
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
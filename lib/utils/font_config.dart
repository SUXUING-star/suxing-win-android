// lib/utils/font_config.dart
import 'dart:io';

class FontConfig {
  static String get defaultFontFamily => Platform.isWindows ? 'Microsoft YaHei' : 'Roboto';
  static List<String> get fontFallback => ['Microsoft YaHei', 'SimHei'];
}
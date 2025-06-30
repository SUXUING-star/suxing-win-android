// lib/models/extension/theme/preset/simple_text_theme.dart

import 'package:flutter/painting.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';

/// [SimpleTextTheme]
/// 不包含 [IconData]
/// 不包含 [backgroundColor]
/// @param [textColor]
/// @param [textLabel]
class SimpleTextTheme {
  final Color textColor; // 文本颜色（用于图标和标签文本）
  final String textLabel; // 标签文本
  /// 构造函数。
  const SimpleTextTheme({
    required this.textColor,
    required this.textLabel,
  });
}

// 接口，用于扩展
abstract class SimpleTextThemeExtension
    implements TextLabelExtension, TextColorExtension {}

// extension EasilyGetTextThemeExtension<T extends SimpleTextThemeExtension> on T {
//   Color get textColor => getTextColor();
//   String get textLabel => getTextLabel();
// }

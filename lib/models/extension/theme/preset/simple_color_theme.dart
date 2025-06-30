// lib/models/extension/theme/preset/simple_color_theme.dart

import 'package:flutter/painting.dart';
import 'package:suxingchahui/models/extension/theme/base/background_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';

/// [SimpleColorThemeExtension]
/// 不包含 [IconData]
/// @param [textColor]
/// @param [backgroundColor]
/// @param [textLabel]
class SimpleColorTheme {
  final Color textColor; // 文本颜色（用于图标和标签文本）
  final Color backgroundColor; // 背景颜色
  final String textLabel; // 标签文本
  /// 构造函数。
  const SimpleColorTheme({
    required this.backgroundColor,
    required this.textColor,
    required this.textLabel,
  });
}

// 接口，用于扩展
abstract class SimpleColorThemeExtension
    implements
        BackgroundColorExtension,
        TextColorExtension,
        TextLabelExtension {}

// extension EasilyGetColorThemeExtension<T extends SimpleColorThemeExtension>
//     on T {
//   Color get backgroundColor => getBackgroundColor();
//   Color get textColor => getTextColor();
//   String get textLabel => getTextLabel();
// }

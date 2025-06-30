// lib/models/extension/theme/preset/common_color_theme.dart

import 'package:flutter/cupertino.dart';
import 'package:suxingchahui/models/extension/theme/base/icon_data_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_color_extension.dart';
import 'package:suxingchahui/models/extension/theme/base/text_label_extension.dart';

import '../base/background_color_extension.dart';

// 这个可以不用了，但保留
/// [CommonColorTheme]
/// @param [backgroundColor]
/// @param [textColor]
/// @param [iconData]
/// @param [textLabel]
class CommonColorTheme {
  final Color backgroundColor; // 背景颜色
  final Color textColor; // 文本颜色（用于图标和标签文本）
  final IconData iconData; // 图标
  final String textLabel; // 标签文本
  /// 构造函数。
  const CommonColorTheme({
    required this.backgroundColor,
    required this.textColor,
    required this.iconData,
    required this.textLabel,
  });
}

// 开始构建基类
abstract class CommonColorThemeExtension
    implements
        BackgroundColorExtension,
        TextColorExtension,
        TextLabelExtension,
        IconDataExtension {}

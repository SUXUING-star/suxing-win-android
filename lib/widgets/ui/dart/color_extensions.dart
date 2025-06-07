// lib/widgets/ui/dart/color_extensions.dart

/// 该文件定义了 Color 的扩展方法，用于安全地设置颜色透明度。
library;

import 'package:flutter/material.dart'; // 导入 Flutter 颜色相关功能

/// `ColorOpacityExtension` 扩展：为 [Color] 类添加功能。
///
/// 该扩展提供了一个方法，用于创建具有指定透明度的新颜色。
extension ColorOpacityExtension on Color {
  /// 创建一个指定透明度的新颜色。
  ///
  /// [opacity] 参数范围为 0.0（完全透明）到 1.0（完全不透明）。
  /// 该方法内部使用 `withAlpha` 避免 `withOpacity` 相关的精度损失。
  Color withSafeOpacity(double opacity) {
    if (opacity < 0.0) opacity = 0.0; // 确保透明度不小于 0.0
    if (opacity > 1.0) opacity = 1.0; // 确保透明度不大于 1.0
    // 将透明度转换为 0-255 的 alpha 值。
    // 使用四舍五入计算 alpha 值。
    return withAlpha((opacity * 255).round());
  }
}

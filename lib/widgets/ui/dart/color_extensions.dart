// lib/widgets/ui/dart/color_extensions.dart
import 'package:flutter/material.dart';

extension ColorOpacityExtension on Color {
  /// Creates a new color with the specified opacity.
  ///
  /// The [opacity] argument must be between 0.0 (fully transparent)
  /// and 1.0 (fully opaque), inclusive.
  ///
  /// This method uses `withAlpha` internally to avoid precision loss
  /// associated with `withOpacity`.
  Color withSafeOpacity(double opacity) {
    if (opacity < 0.0) opacity = 0.0;
    if (opacity > 1.0) opacity = 1.0;
    // 将 0.0-1.0 的 opacity 转换为 0-255 的 alpha 值
    // (opacity * 255).round() 是一种常见的转换方式
    return withAlpha((opacity * 255).round());
  }
}

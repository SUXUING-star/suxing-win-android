// lib/widgets/ui/components/base_tag_view.dart

/// 定义了 [BaseTagView] 组件，一个支持多种样式的可复用标签视图。
///
/// 该库提供了一个统一的基础组件，用于在整个应用中创建视觉风格一致的标签。
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/game/game/enrich_game_tag.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

/// 一个多功能的基础标签组件，支持磨砂和实心两种样式。
///
/// 该组件是 App 内所有标签的统一样式基础，可以通过 [isFrosted]
/// 参数在两种视觉风格之间切换，以适应不同的背景和使用场景。
class BaseTagView extends StatelessWidget {
  /// 标签显示的文本。
  final String text;

  /// 标签的基础颜色，所有派生颜色均基于此。
  final Color baseColor;

  /// 是否为迷你模式，`true` 会使用较小的尺寸和圆角。
  final bool isMini;

  /// 标签旁显示的可选数量。
  final int? count;

  /// 是否启用磨砂玻璃效果。
  ///
  /// `true` - 渲染半透明、带边框的磨砂效果。
  /// `false` - 渲染带有轻微透明度的实心背景效果。
  final bool isFrosted;

  /// 创建一个基础标签视图。
  const BaseTagView({
    super.key,
    required this.text,
    required this.baseColor,
    this.isMini = true,
    this.count,
    this.isFrosted = true,
  });

  // --- 样式常量定义 ---

  /// 迷你模式下的圆角半径。
  static const double miniRadius = 12.0;

  /// 常规模式下的圆角半径。
  static const double normalRadius = 20.0;

  /// 专用于 `GameTagItem` 的圆角半径 (等同于迷你模式)。
  static const double tagRadius = miniRadius;

  @override
  Widget build(BuildContext context) {
    // 根据 isMini 动态计算尺寸
    final double horizontalPadding = isMini ? 8.0 : 12.0;
    final double verticalPadding = isMini ? 4.0 : 6.0;
    final double fontSize = isMini ? 12.0 : 14.0;
    final double countFontSize = isMini ? 10.0 : 11.0;
    final double borderRadius = isMini ? miniRadius : normalRadius;

    // 根据 isFrosted 开关，选择渲染不同的视图。
    if (isFrosted) {
      return _buildFrostedView(borderRadius, horizontalPadding, verticalPadding,
          fontSize, countFontSize);
    } else {
      return _buildSolidView(borderRadius, horizontalPadding, verticalPadding,
          fontSize, countFontSize);
    }
  }

  /// 构建磨砂效果的视图。
  Widget _buildFrostedView(double borderRadius, double hPadding,
      double vPadding, double fSize, double cSize) {
    final Color textColor = baseColor;
    final Border border =
        Border.all(color: baseColor.withSafeOpacity(0.5), width: 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding:
              EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
          decoration: BoxDecoration(
            // 使用 withSafeOpacity 确保透明度值在安全范围内
            color: baseColor.withSafeOpacity(0.15),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
          ),
          child: _buildChildRow(textColor, FontWeight.w500, fSize, cSize),
        ),
      ),
    );
  }

  /// 构建实心效果的视图。
  Widget _buildSolidView(double borderRadius, double hPadding, double vPadding,
      double fSize, double cSize) {
    // 根据背景色动态计算高对比度的文本颜色，保证可读性。
    final Color textColor =
        EnrichGameTag.getTagTextColorForBackground(baseColor);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      decoration: BoxDecoration(
        // 为实心背景色增加轻微透明度，避免视觉上过于死板。
        color: baseColor.withSafeOpacity(0.9),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: _buildChildRow(textColor, FontWeight.w500, fSize, cSize),
    );
  }

  /// 构建标签内部的子组件行 (文本和可选的数量角标)。
  Widget _buildChildRow(
      Color textColor, FontWeight fontWeight, double fSize, double cSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: fSize,
              // 文本字体粗细统一为 w500，以保证视觉一致性。
              fontWeight: fontWeight,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: textColor.withSafeOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: textColor,
                fontSize: cSize,
                // 数量角标使用粗体以突出显示。
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

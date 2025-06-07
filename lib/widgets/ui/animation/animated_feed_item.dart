// lib/widgets/ui/animation/animated_feed_item.dart

/// 该文件定义了 AnimatedFeedItem 组件，一个封装了交错动画的列表项。
/// AnimatedFeedItem 为列表项提供淡入和滑入动画效果。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // 导入交错动画库

/// `AnimatedFeedItem` 类：封装了 `flutter_staggered_animations` 的通用列表项动画组件。
///
/// 该组件为列表项提供交错的淡入和滑入效果。
class AnimatedFeedItem extends StatelessWidget {
  final int position; // 列表项在列表中的位置，用于计算交错延迟
  final Widget child; // 要应用动画的子组件
  final Duration duration; // 动画持续时间
  final double verticalOffset; // 垂直方向的滑入偏移量
  final double? horizontalOffset; // 水平方向的滑入偏移量

  /// 构造函数。
  ///
  /// [position]：列表项位置。
  /// [child]：子组件。
  /// [duration]：动画时长。
  /// [verticalOffset]：垂直偏移量。
  /// [horizontalOffset]：水平偏移量。
  const AnimatedFeedItem({
    super.key,
    required this.position,
    required this.child,
    this.duration = const Duration(milliseconds: 375),
    this.verticalOffset = 50.0,
    this.horizontalOffset,
  });

  /// 构建动画列表项组件。
  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: position, // 列表项位置
      duration: duration, // 动画持续时间
      child: SlideAnimation(
        // 滑入动画
        verticalOffset: verticalOffset, // 垂直偏移量
        horizontalOffset: horizontalOffset, // 水平偏移量
        child: FadeInAnimation(
          // 淡入动画
          child: child, // 子组件
        ),
      ),
    );
  }
}

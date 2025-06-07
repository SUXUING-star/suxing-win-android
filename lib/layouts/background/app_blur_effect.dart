// lib/layouts/background/app_blur_effect.dart

/// 该文件定义了 AppBlurEffect 组件，用于在背景上应用模糊和渐变效果。
/// AppBlurEffect 根据窗口调整大小状态控制模糊效果的显示。
library;

import 'dart:ui'; // 图像过滤器所需
import 'package:flutter/cupertino.dart'; // Cupertino UI 框架（此处仅导入，实际使用 Flutter Material）

/// `AppBlurEffect` 类：应用模糊效果组件。
///
/// 该组件在背景上应用模糊和渐变叠加层。
class AppBlurEffect extends StatelessWidget {
  final bool isCurrentlyResizing; // 标识窗口是否正在调整大小
  final List<Color> gradientColors; // 渐变颜色列表

  /// 构造函数。
  ///
  /// [key]：可选的 Key。
  /// [isCurrentlyResizing]：是否正在调整窗口大小。
  /// [gradientColors]：渐变颜色列表。
  const AppBlurEffect({
    required this.isCurrentlyResizing,
    required this.gradientColors,
    super.key,
  });

  /// 构建模糊和渐变叠加层 UI。
  ///
  /// [context]：Build 上下文。
  /// 返回一个 `Offstage` 组件，根据 `isCurrentlyResizing` 状态控制模糊效果的显示。
  @override
  Widget build(BuildContext context) {
    return Offstage(
      // 控制子组件是否显示
      offstage: isCurrentlyResizing, // 窗口调整大小时隐藏模糊效果
      child: BackdropFilter(
        // 背景滤镜
        filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0), // 应用模糊滤镜
        child: Container(
          // 渐变容器
          decoration: BoxDecoration(
            // 装饰
            gradient: LinearGradient(
              // 线性渐变
              colors: gradientColors, // 渐变颜色
              begin: Alignment.topCenter, // 渐变起始点
              end: Alignment.bottomCenter, // 渐变结束点
            ),
          ),
        ),
      ),
    );
  }
}

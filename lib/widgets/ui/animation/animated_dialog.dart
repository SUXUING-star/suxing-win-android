// lib/widgets/ui/animation/animated_dialog.dart

/// 该文件定义了 AnimatedDialog 类，提供通用动画显示对话框的功能。
/// 该类用于以缩放和淡入动画效果显示对话框。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件

/// `AnimatedDialog` 类：提供通用动画显示对话框的功能。
///
/// 该类用于以缩放和淡入动画效果显示对话框。
class AnimatedDialog {
  /// 显示带有动画效果的通用对话框。
  ///
  /// [context]：Build 上下文。
  /// [pageBuilder]：构建对话框内容的函数。
  /// [barrierDismissible]：是否可点击外部关闭对话框。
  /// [barrierLabel]：语义标签。
  /// [barrierColor]：背景颜色。
  /// [transitionDuration]：过渡动画时长。
  /// [transitionCurve]：过渡动画曲线。
  /// [maxWidth]：对话框初始最大宽度。
  /// 返回一个 Future，表示对话框关闭时的结果。
  static Future<T?> showAppAnimatedDialog<T>({
    required BuildContext context,
    required Widget Function(BuildContext context) pageBuilder,
    bool barrierDismissible = true,
    String? barrierLabel,
    Color barrierColor = Colors.black54,
    Duration transitionDuration = const Duration(milliseconds: 350),
    Curve transitionCurve = Curves.easeOutBack,
    double maxWidth = 300,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible, // 是否可点击外部关闭
      barrierLabel: barrierLabel ??
          MaterialLocalizations.of(context).modalBarrierDismissLabel, // 语义标签
      barrierColor: barrierColor, // 背景颜色
      transitionDuration: transitionDuration, // 过渡动画时长
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return pageBuilder(buildContext); // 返回 pageBuilder 构建的 Widget
      },
      transitionBuilder: (BuildContext buildContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation, // 父动画
            curve: transitionCurve, // 动画曲线
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation, // 父动画
              curve: Curves.easeIn, // 动画曲线
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth), // 约束最大宽度
                child: child, // 对话框内容
              ),
            ),
          ),
        );
      },
    );
  }
}

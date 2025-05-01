import 'package:flutter/material.dart';

class animatedDialog {
  // --- 通用动画显示函数 (保持或移到工具类) ---
// 这个函数保持不变，它负责初始的进入动画和定位
 static Future<T?> showAppAnimatedDialog<T>({
    required BuildContext context,
    required Widget Function(BuildContext context) pageBuilder, // 构建对话框内容的函数
    bool barrierDismissible = true,
    String? barrierLabel,
    Color barrierColor = Colors.black54,
    Duration transitionDuration = const Duration(milliseconds: 350),
    Curve transitionCurve = Curves.easeOutBack, // 动画曲线
    double maxWidth = 300, // 对话框初始最大宽度
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel ??
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
// 直接返回 pageBuilder 构建的 Widget (BaseInputDialog 实例)
// 这个实例内部会处理 Transform 和 GestureDetector
        return pageBuilder(buildContext);
      },
      transitionBuilder: (BuildContext buildContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child) {
// 动画效果 (缩放 + 淡入) - 应用于 BaseInputDialog 实例
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: transitionCurve,
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            ),
// 使用 Center 和 ConstrainedBox 约束对话框 *初始* 的大小和位置
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child, // child 就是 pageBuilder 返回的 BaseInputDialog 实例
              ),
            ),
          ),
        );
      },
    );
  }
}

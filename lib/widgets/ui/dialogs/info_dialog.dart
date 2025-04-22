// lib/widgets/ui/dialogs/info_dialog.dart
import 'package:flutter/material.dart';
import 'dart:async'; // 仅需要 VoidCallback

// --- 通用动画显示函数 (保持或移到工具类) ---
Future<void> showAppAnimatedDialog({ // 返回 Future<void>
  required BuildContext context,
  required Widget Function(BuildContext context) pageBuilder,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color barrierColor = Colors.black54,
  Duration transitionDuration = const Duration(milliseconds: 350),
  Curve transitionCurve = Curves.easeOutBack,
  double maxWidth = 300,
}) {
  return showGeneralDialog<void>( // 泛型是 void
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      // pageBuilder 返回要显示的 Widget (这里是 CustomInfoDialog 实例)
      return pageBuilder(buildContext);
    },
    transitionBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
      // 动画效果
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: transitionCurve),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          // --- 确保动画包裹的是居中和约束后的 Widget ---
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child, // child 是 pageBuilder 返回的 CustomInfoDialog
            ),
          ),
          // ------------------------------------------
        ),
      );
    },
  );
}


/// 自定义信息对话框 Widget
/// *** 恢复为 StatelessWidget ***
class CustomInfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String closeButtonText;
  final VoidCallback? onClose; // 关闭回调
  final IconData iconData; // 图标
  final Color iconColor; // 图标颜色
  final Color? closeButtonColor; // 关闭按钮颜色

  // *** 恢复构造函数 ***
  const CustomInfoDialog({
    super.key,
    required this.title,     // title 是 required
    required this.message,    // message 是 required
    this.closeButtonText = '好的',
    this.onClose,
    this.iconData = Icons.info_outline, // 默认信息图标
    this.iconColor = Colors.blue,       // 默认蓝色
    this.closeButtonColor,             // 默认跟随主题色
  });

  /// 显示自定义信息对话框的静态方法
  /// *** 保持原有签名 ***
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String closeButtonText = '好的',
    VoidCallback? onClose,
    IconData iconData = Icons.info_outline,
    Color iconColor = Colors.blue,
    Color? closeButtonColor,
    bool barrierDismissible = true, // Info 默认允许点击外部关闭
    Duration transitionDuration = const Duration(milliseconds: 350),
    Curve transitionCurve = Curves.easeOutBack,
    double maxWidth = 300, // 允许外部设置最大宽度
  }) {
    // *** 调用通用动画函数，pageBuilder 返回 CustomInfoDialog 实例 ***
    return showAppAnimatedDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      maxWidth: maxWidth, // 传递 maxWidth
      pageBuilder: (buildContext) { // 这里 context 名字是 buildContext 避免冲突
        return CustomInfoDialog( // 创建实例
          title: title,
          message: message,
          closeButtonText: closeButtonText,
          onClose: onClose,
          iconData: iconData,
          iconColor: iconColor,
          closeButtonColor: closeButtonColor,
        );
      },
    );
  }

  // *** build 方法负责 UI 渲染 ***
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // *** 不再需要 Center 和 ConstrainedBox，因为 showAppAnimatedDialog 会处理 ***
    return Material( // 根 Widget 是 Material
      color: Colors.white,
      elevation: 6.0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- 图标 ---
            Icon(iconData, color: iconColor, size: 48),
            const SizedBox(height: 16),
            // --- 标题 ---
            Text( title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith( fontWeight: FontWeight.bold, color: Colors.black87, ), ),
            const SizedBox(height: 10),
            // --- 消息内容 ---
            Text( message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith( height: 1.5, color: Colors.black54, ), ),
            const SizedBox(height: 24),
            // --- 单个动作按钮 ---
            SizedBox(
              width: double.infinity, // 按钮宽度撑满
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 点击按钮关闭对话框
                  onClose?.call(); // 执行外部传入的回调
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: closeButtonColor ?? theme.primaryColor, // 使用传入颜色或主题色
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 2,
                  shadowColor: (closeButtonColor ?? theme.primaryColor).withOpacity(0.4),
                  minimumSize: const Size(0, 48),
                ),
                child: Text(closeButtonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
} // End of CustomInfoDialog StatelessWidget


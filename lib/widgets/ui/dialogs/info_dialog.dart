import 'package:flutter/material.dart';
import 'dart:async'; // 仅需要 VoidCallback

// 可以将 showGeneralDialog 的通用逻辑提取出来 (可选)
class _DialogUtils {
  static Future<void> showAnimatedDialog({
    required BuildContext context,
    required bool barrierDismissible,
    required Duration transitionDuration,
    required Curve transitionCurve,
    required Widget dialogPageBuilder(BuildContext buildContext,
        Animation<double> animation, Animation<double> secondaryAnimation),
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: transitionDuration,
      pageBuilder: dialogPageBuilder,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: transitionCurve),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          ),
        );
      },
    );
  }
}

/// 自定义信息对话框 Widget
///
/// 显示一个带有图标、标题、消息以及单个关闭按钮的对话框。
class CustomInfoDialog extends StatelessWidget {
  // 可以是 StatelessWidget
  final String title;
  final String message;
  final String closeButtonText;
  final VoidCallback? onClose; // 关闭回调
  final IconData iconData; // 图标
  final Color iconColor; // 图标颜色
  final Color? closeButtonColor; // 关闭按钮颜色

  const CustomInfoDialog({
    Key? key,
    required this.title,
    required this.message,
    this.closeButtonText = '好的',
    this.onClose,
    this.iconData = Icons.info_outline, // 默认信息图标
    this.iconColor = Colors.blue, // 默认蓝色
    this.closeButtonColor, // 默认跟随主题色
  }) : super(key: key);

  /// 显示自定义信息对话框的静态方法
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
  }) {
    // 使用提取的工具类或直接调用 showGeneralDialog
    return _DialogUtils.showAnimatedDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      dialogPageBuilder: (buildContext, animation, secondaryAnimation) {
        return CustomInfoDialog(
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
    /* 或者不提取，直接在这里写 showGeneralDialog
     return showGeneralDialog<void>(
       context: context,
       barrierDismissible: barrierDismissible,
       // ... 其他 showGeneralDialog 参数 ...
       pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
         return CustomInfoDialog(...);
       },
       transitionBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
         // ... transition builder ...
       },
     );
     */
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300, minWidth: 280),
        child: Material(
          color: Colors.white,
          elevation: 6.0,
          shadowColor: Colors.black26,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                // --- 消息内容 ---
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),

                // --- 单个动作按钮 ---
                SizedBox(
                  width: double.infinity, // 按钮宽度撑满
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // 关闭对话框
                      onClose?.call(); // 执行回调
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: closeButtonColor ?? theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                      shadowColor: (closeButtonColor ?? theme.primaryColor)
                          .withOpacity(0.4),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(closeButtonText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

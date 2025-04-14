// lib/widgets/ui/dialogs/base_input_dialog.dart
import 'package:flutter/material.dart';
import 'dart:async';

// --- 通用动画显示函数 (可以放在单独的工具类里) ---
Future<T?> showAppAnimatedDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) pageBuilder, // 构建对话框内容的函数
  bool barrierDismissible = true,
  String? barrierLabel,
  Color barrierColor = Colors.black54,
  Duration transitionDuration = const Duration(milliseconds: 350),
  Curve transitionCurve = Curves.easeOutBack, // 动画曲线
  double maxWidth = 300, // 对话框最大宽度
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
      // 直接返回 pageBuilder 构建的 Widget
      return pageBuilder(buildContext);
    },
    transitionBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
      // 动画效果 (缩放 + 淡入)
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
          // 使用 Center 和 ConstrainedBox 约束对话框大小和位置
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child, // child 就是 pageBuilder 返回的 Widget
            ),
          ),
        ),
      );
    },
  );
}


// --- 底层通用输入/确认对话框 ---
class BaseInputDialog<T> extends StatefulWidget {
  final String title;
  // 内容区域由外部构建，更灵活
  final Widget Function(BuildContext context) contentBuilder;
  final String cancelButtonText;
  final String confirmButtonText;
  final Color confirmButtonColor;
  // 确认回调，返回 Future<T?>
  // 返回 T 表示成功并关闭对话框，返回 null 表示校验失败或不想关闭
  final Future<T?> Function() onConfirm;
  final VoidCallback? onCancel; // 可选的取消回调
  final IconData? iconData; // 可选的顶部图标
  final Color? iconColor;   // 可选的图标颜色

  const BaseInputDialog({
    Key? key,
    required this.title,
    required this.contentBuilder, // 必须提供内容构建器
    required this.onConfirm,       // 必须提供确认回调
    this.cancelButtonText = '取消',
    this.confirmButtonText = '确认',
    Color? confirmButtonColor,     // 允许外部指定颜色
    this.onCancel,
    this.iconData,
    this.iconColor,
  }) : confirmButtonColor = confirmButtonColor ?? Colors.blue, // 默认确认按钮为蓝色
        super(key: key);


  /// 显示底层输入对话框的静态方法
  /// 返回 Future<T?>: 确认时返回 T，取消或关闭时返回 null
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext context) contentBuilder, // 内容构建器
    required Future<T?> Function() onConfirm,                   // 确认回调
    String cancelButtonText = '取消',
    String confirmButtonText = '确认',
    Color? confirmButtonColor,
    VoidCallback? onCancel,
    IconData? iconData,                                        // 可选图标
    Color? iconColor,
    double maxWidth = 300,
    bool barrierDismissible = true,                             // 默认允许点击外部关闭
  }) {
    final theme = Theme.of(context);
    // 确定最终使用的颜色
    final effectiveIconColor = iconColor ?? theme.primaryColor;
    final effectiveConfirmButtonColor = confirmButtonColor ?? theme.primaryColor;

    // 使用 Completer 处理异步结果
    final completer = Completer<T?>();

    // 调用通用动画对话框显示函数
    showAppAnimatedDialog<void>( // showAppAnimatedDialog 本身不关心返回 T
      context: context,
      maxWidth: maxWidth,
      barrierDismissible: barrierDismissible, // 传递 barrierDismissible
      pageBuilder: (BuildContext buildContext) {
        // 构建 BaseInputDialog 实例
        return BaseInputDialog<T>( // 传递泛型类型
          title: title,
          contentBuilder: contentBuilder,
          onConfirm: () async {
            try {
              // 调用外部传入的 onConfirm，它可能抛出异常或返回 null
              T? result = await onConfirm();
              // 如果 onConfirm 返回非 null (表示成功并希望关闭)
              // 并且 completer 还没完成 (防止重复完成)
              if (result != null && !completer.isCompleted) {
                completer.complete(result); // 使用成功结果完成 future
              }
              // 返回结果给 BaseInputDialog 内部状态机，用于决定是否 pop
              return result;
            } catch (e) {
              // 如果 onConfirm 抛出异常
              if (!completer.isCompleted) {
                completer.completeError(e); // 使用错误完成 future
              }
              // 把异常继续抛给 BaseInputDialog 的 _handleConfirm
              rethrow;
            }
          },
          cancelButtonText: cancelButtonText,
          confirmButtonText: confirmButtonText,
          confirmButtonColor: effectiveConfirmButtonColor,
          onCancel: onCancel,
          iconData: iconData,
          iconColor: effectiveIconColor,
        );
      },
    ).then((_) {
      // 当对话框通过非按钮方式关闭时 (例如 barrierDismissible, back button)
      // 检查 completer 是否已经完成，如果没有，则视为取消
      if (!completer.isCompleted) {
        completer.complete(null); // 完成 future 并返回 null
      }
    });

    // 返回这个 future，调用者可以 await 它来获取结果
    return completer.future;
  }


  @override
  State<BaseInputDialog<T>> createState() => _BaseInputDialogState<T>();
}

class _BaseInputDialogState<T> extends State<BaseInputDialog<T>> {
  bool _isProcessing = false; // 标记确认操作是否正在进行

  /// 处理确认按钮点击
  Future<void> _handleConfirm() async {
    if (_isProcessing) return; // 防止重复点击
    setState(() { _isProcessing = true; }); // 进入处理中状态

    T? result; // 存储 onConfirm 的结果
    bool shouldPop = false; // 标记是否应该关闭对话框

    try {
      // 调用 widget 中定义的 onConfirm 回调
      result = await widget.onConfirm();
      // 如果 onConfirm 返回非 null，表示操作成功，应该关闭对话框
      if (result != null) {
        shouldPop = true;
      }
      // 如果 onConfirm 返回 null，表示校验失败或操作未完成，不关闭对话框
    } catch (e) {
      // 如果 onConfirm 抛出异常，标记需要关闭对话框，并将异常向上抛出
      shouldPop = true;
      // 不需要在这里处理异常显示，让调用 show 方法的地方处理 Future 的错误
      // Log error: print('BaseInputDialog: onConfirm error: $e');
      rethrow; // 继续抛出异常
    } finally {
      // 无论成功、失败还是返回 null，最后都重置处理状态
      if (mounted) { // 检查是否还在挂载
        setState(() { _isProcessing = false; });
      }
      // 根据 shouldPop 决定是否关闭对话框
      // 放在 finally 确保即使出错也能尝试关闭
      if (shouldPop && mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // 关闭对话框
      }
    }
  }

  /// 处理取消按钮点击
  void _handleCancel() {
    if (_isProcessing) return; // 处理中则不允许取消
    Navigator.pop(context); // 关闭对话框
    widget.onCancel?.call(); // 调用外部传入的 onCancel 回调
    // 外部等待的 Future 会 resolve 为 null (由 show 方法处理)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // --- 对话框根 Widget ---
    return Material(
      type: MaterialType.card, // 使用 card 类型，自带圆角和阴影效果
      color: Colors.white, // 对话框背景色
      elevation: 6.0,      // 阴影强度
      shadowColor: Colors.black38, // 阴影颜色
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // 圆角
      clipBehavior: Clip.antiAlias, // 裁剪内容以匹配圆角
      child: Padding( // 内部边距
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16), // 调整边距
        child: Column( // 垂直布局
          mainAxisSize: MainAxisSize.min, // 高度自适应
          children: [
            // --- 可选图标 ---
            if (widget.iconData != null) ...[
              Icon(
                widget.iconData!,
                color: widget.iconColor ?? theme.primaryColor, // 使用传入颜色或主题色
                size: 40,
              ),
              const SizedBox(height: 16),
            ],

            // --- 标题 ---
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith( // 使用大标题样式
                fontWeight: FontWeight.w600, // 加粗一点
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16), // 标题和内容间距

            // --- 动态内容区域 ---
            widget.contentBuilder(context), // 调用外部构建器生成内容

            const SizedBox(height: 24), // 内容和按钮间距

            // --- 按钮行 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // 按钮靠右
              children: [
                // --- 取消按钮 ---
                TextButton(
                  onPressed: _isProcessing ? null : _handleCancel, // 处理中禁用
                  style: TextButton.styleFrom(
                    foregroundColor: theme.textTheme.bodyMedium?.color, // 文本颜色
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: const Size(80, 40), // 最小尺寸
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // 轻微圆角
                  ),
                  child: Text(widget.cancelButtonText),
                ),
                const SizedBox(width: 8), // 按钮间距

                // --- 确认按钮 或 加载指示器 ---
                _isProcessing
                    ? Container( // 加载状态显示指示器
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  height: 44, // 与按钮高度一致
                  constraints: const BoxConstraints(minWidth: 88),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
                    : ElevatedButton( // 正常状态显示按钮
                  onPressed: _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.confirmButtonColor, // 使用传入或默认的确认按钮颜色
                    foregroundColor: Colors.white, // 按钮文字颜色
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // 圆角
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 2,
                    shadowColor: widget.confirmButtonColor.withOpacity(0.4),
                    minimumSize: const Size(88, 44), // 最小尺寸
                  ),
                  child: Text(widget.confirmButtonText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} // End of _BaseInputDialogState